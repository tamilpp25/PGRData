XDlcHotReload = XDlcHotReload or {}

function XDlcHotReload.Reload(fileName)
    if not XMain.IsEditorDebug then return false end

    --local info = debug.getinfo(2)
    if not package.loaded[fileName] then
        XLog.Error("XHotReload.Reload reload file error: file never loaded, fileName is: ", fileName)
        return false
    end

    local oldModule = package.loaded[fileName]
    package.loaded[fileName] = nil

    local ok, err = pcall(require, fileName)
    if not ok then
        package.loaded[fileName] = oldModule
        XLog.Error("XHotReload.Reload reload file error: ", err)
        return false
    end

    local newModule = package.loaded[fileName]

    UpdateClassType(newModule, oldModule)

    package.loaded[fileName] = oldModule
    XLog.Debug("Dlc XHotReload.Reload suc, fileName is: ", fileName)
	return true
end