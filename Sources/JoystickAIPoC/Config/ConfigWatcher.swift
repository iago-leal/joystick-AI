import Foundation

/// Observação do arquivo de configuração sem varredura (`003-editor-atalhos` D-16, RF-03). Só na main thread.
///
/// Observa o diretório do arquivo e, se ele for *link* simbólico, o do destino; sem o diretório, o ancestral
/// existente mais próximo, trocado pelo filho quando este surge. O diretório cobre a troca atômica dos editores, que
/// substitui o arquivo; o descritor do próprio arquivo cobre a escrita no lugar (`echo >`), que não altera o diretório.
/// Cada evento reabre as observações e agenda uma releitura 150 ms depois do último.
final class ConfigWatcher {
    static let reloadDelay: DispatchTimeInterval = .milliseconds(150)

    private let url: URL
    private let onChange: () -> Void
    private var sources: [String: DispatchSourceFileSystemObject] = [:]
    private var pendingReload: DispatchWorkItem?

    init(url: URL, onChange: @escaping () -> Void) {
        self.url = url
        self.onChange = onChange
    }

    func start() {
        dispatchPrecondition(condition: .onQueue(.main))
        refreshSources()
    }

    func stop() {
        pendingReload?.cancel()
        pendingReload = nil
        sources.values.forEach { $0.cancel() }
        sources.removeAll()
    }

    /// Caminhos observados: diretórios (ou ancestrais existentes) do arquivo e do destino do *link*, e o destino.
    private func watchedPaths() -> Set<String> {
        let destination = ConfigWriter.resolveLinks(url)
        var paths: Set<String> = [
            Self.nearestExistingDirectory(of: url.deletingLastPathComponent()),
            Self.nearestExistingDirectory(of: destination.deletingLastPathComponent()),
        ]
        if FileManager.default.fileExists(atPath: destination.path) {
            paths.insert(destination.path)
        }
        return paths
    }

    private static func nearestExistingDirectory(of directory: URL) -> String {
        var current = directory.standardizedFileURL
        var isDirectory: ObjCBool = false
        while current.path != "/" && !(FileManager.default.fileExists(atPath: current.path, isDirectory: &isDirectory) && isDirectory.boolValue) {
            current.deleteLastPathComponent()
        }
        return current.path
    }

    /// Reabre as observações: o arquivo pode ter sido trocado, o diretório criado ou o *link* redirecionado.
    private func refreshSources() {
        let wanted = watchedPaths()
        for (path, source) in sources where !wanted.contains(path) {
            source.cancel()
            sources[path] = nil
        }
        let destination = ConfigWriter.resolveLinks(url).path
        for path in wanted {
            // O descritor do arquivo fica inválido após troca atômica; é sempre reaberto.
            if path == destination, let old = sources[path] {
                old.cancel()
                sources[path] = nil
            }
            guard sources[path] == nil else { continue }
            let descriptor = open(path, O_EVTONLY)
            guard descriptor >= 0 else { continue }
            let source = DispatchSource.makeFileSystemObjectSource(
                fileDescriptor: descriptor, eventMask: [.write, .extend, .rename, .delete], queue: .main)
            source.setEventHandler { [weak self] in self?.handleEvent() }
            source.setCancelHandler { close(descriptor) }
            source.resume()
            sources[path] = source
        }
    }

    private func handleEvent() {
        refreshSources()
        pendingReload?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.pendingReload = nil
            // Um arquivo recriado depois do último evento precisa de observação própria.
            self.refreshSources()
            self.onChange()
        }
        pendingReload = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.reloadDelay, execute: work)
    }
}
