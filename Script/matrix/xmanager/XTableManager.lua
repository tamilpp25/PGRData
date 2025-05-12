XTableManager = XTableManager or {}

XTableManager.TableLoadType =
{
    Tab = 1,
    Bytes = 2,
    Pack = 3
}
XTableManager.CryptoEnable = false

local router = require("XManager/XTableLoaders/XTableLoadRouter")
local tabLoader = require("XManager/XTableLoaders/XTableTabLoader")
local bytesLoader = require("XManager/XTableLoaders/XTableBytesLoader")
local packLoader = require("XManager/XTableLoaders/XTablePackLoader")
function XTableManager.GetPackLoader()
    return packLoader
end

function XTableManager.GetBytesLoader()
    return bytesLoader
end

XTableManager.ForceRelease = false

--============= 外部函数 ============
--为了兼容已有的业务调用需求，因此接口上无法做到统一，所以两个loader接受的参数是不同的
function XTableManager.ReadAllByIntKey(path, xTable, identifier)
    local loadType = router.GetLoadType(path)
    if loadType == XTableManager.TableLoadType.Tab then
        return tabLoader.ReadAllByIntKey(path, xTable, identifier)
    elseif loadType == XTableManager.TableLoadType.Bytes then
        return bytesLoader.ReadAllByIntKey(path, xTable, identifier)
    else
        return packLoader.ReadAllByIntKey(path, xTable, identifier)
    end
end

function XTableManager.ReadAllByStringKey(path, xTable, identifier)
    local loadType = router.GetLoadType(path)
    if loadType == XTableManager.TableLoadType.Tab then
        return tabLoader.ReadAllByStringKey(path, xTable, identifier)
    elseif loadType == XTableManager.TableLoadType.Bytes then
        return bytesLoader.ReadAllByStringKey(path, xTable, identifier)
    else
        return packLoader.ReadAllByStringKey(path, xTable, identifier)
    end
end

function XTableManager.ReadByIntKey(path, xTable, identifier)
    local loadType = router.GetLoadType(path)
    if loadType == XTableManager.TableLoadType.Tab then
        return tabLoader.ReadByIntKey(path, xTable, identifier)
    elseif loadType == XTableManager.TableLoadType.Bytes then
        return bytesLoader.ReadByIntKey(path, xTable, identifier)
    else
        return packLoader.ReadByIntKey(path, xTable, identifier)
    end
end

function XTableManager.ReadByStringKey(path, xTable, identifier)
    local loadType = router.GetLoadType(path)
    if loadType == XTableManager.TableLoadType.Tab then
        return tabLoader.ReadByStringKey(path, xTable, identifier)
    elseif loadType == XTableManager.TableLoadType.Bytes then
        return bytesLoader.ReadByStringKey(path, xTable, identifier)
    else
        return packLoader.ReadByStringKey(path, xTable, identifier)
    end
end

function XTableManager.ReadArray(path, xTable, identifier)
    XLog.Error("XTableManager.ReadArray接口已弃用找 梁骞")
    return tabLoader.ReadArray(path, xTable, identifier)
end

function XTableManager.ReleaseAll(unload)
    bytesLoader.ReleaseCache()
    packLoader.ReleaseCache()
end

--释放所有io
function XTableManager.ReleaseIo()
    packLoader.ReleaseIo()
end

function XTableManager.CheckTableExist(path)
    return CS.XTableManager.CheckTableExist(path)
end


function XTableManager.ReleaseTable(path)
    --TODO 增加表格释放接口
    local loadType = router.GetLoadType(path)
    if loadType == XTableManager.TableLoadType.Bytes then
        bytesLoader.ReleaseFull(path)
    elseif loadType == XTableManager.TableLoadType.Pack then
        packLoader.ReleaseFull(path)
    end
end