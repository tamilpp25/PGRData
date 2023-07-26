XTableManager = XTableManager or {}

XTableManager.TableLoadType =
{
    Tab = 1,
    Bytes = 2
}

local router = require("XManager/XTableLoaders/XTableLoadRouter")
local tabLoader = require("XManager/XTableLoaders/XTableTabLoader")
local bytesLoader = require("XManager/XTableLoaders/XTableBytesLoader")

XTableManager.ForceRelease = false


--============= 外部函数 ============
--为了兼容已有的业务调用需求，因此接口上无法做到统一，所以两个loader接受的参数是不同的
function XTableManager.ReadAllByIntKey(path, xTable, identifier)
    if router.GetLoadType(path) == XTableManager.TableLoadType.Tab then
        return tabLoader.ReadAllByIntKey(path, xTable, identifier)
    else
        return bytesLoader.ReadAllByIntKey(path, xTable, identifier)
    end
end

function XTableManager.ReadAllByStringKey(path, xTable, identifier)
    if router.GetLoadType(path) == XTableManager.TableLoadType.Tab then
        return tabLoader.ReadAllByStringKey(path, xTable, identifier)
    else
        return bytesLoader.ReadAllByStringKey(path, xTable, identifier)
    end
end

function XTableManager.ReadByIntKey(path, xTable, identifier)
    if router.GetLoadType(path) == XTableManager.TableLoadType.Tab then
        return tabLoader.ReadByIntKey(path, xTable, identifier)
    else
        return bytesLoader.ReadByIntKey(path, xTable, identifier)
    end
end

function XTableManager.ReadByStringKey(path, xTable, identifier)
    if router.GetLoadType(path) == XTableManager.TableLoadType.Tab then
        return tabLoader.ReadByStringKey(path, xTable, identifier)
    else
        return bytesLoader.ReadByStringKey(path, xTable, identifier)
    end
end

function XTableManager.ReadArray(path, xTable, identifier)
    return tabLoader.ReadArray(path, xTable, identifier)
end

function XTableManager.ReleaseAll(unload)
    bytesLoader.ReleaseCache()
end

function XTableManager.CheckTableExist(path)
    return CS.XTableManager.CheckTableExist(path)
end


function XTableManager.ReleaseTable(path)
    --TODO 增加表格释放接口
    if router.GetLoadType(path) == XTableManager.TableLoadType.Tab then
        return
    end
    bytesLoader.ReleaseFull(path)
end