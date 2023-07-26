--该类用来判断表格该走哪种模式读取
local router = {}

-- 从外部目录读取tab
local UseExternalTable = (CS.XTableManager.UseExternTable == true)
local USE_BYTES = 1
local IsUseBytes = (CS.XTableManager.UseBytes == USE_BYTES and not UseExternalTable)

local function IsDlcTablePath(path)
    return string.find(path, "StatusSyncFight") ~= nil or string.find(path, "ChasingShadows") ~= nil or
            string.find(path, "DlcHunt") ~= nil
end

--表格走Tab还是Bytes读取的规则判断
function router.GetLoadType(path)
    if not IsUseBytes then
        return XTableManager.TableLoadType.Tab
    end

    if IsDlcTablePath(path) then
        return XTableManager.TableLoadType.Tab
    end

    return XTableManager.TableLoadType.Bytes
end

return router