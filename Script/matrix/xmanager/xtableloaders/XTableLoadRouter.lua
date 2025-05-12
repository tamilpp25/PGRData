--该类用来判断表格该走哪种模式读取
local router = {}

-- 从外部目录读取tab
local UseExternalTable = (CS.XTableManager.UseExternTable == true)
local USE_BYTES = 1
-- local USE_PACK = 2
local IsUseBytes = CS.XTableManager.UseBytes == USE_BYTES
local IsUsePack = (CS.XRemoteConfig.PackCacheCount ~= 0 and not UseExternalTable)

--表格走Tab还是Bytes读取的规则判断
function router.GetLoadType(path)
    if not IsUsePack then --分开来判断
        if not IsUseBytes then
            return XTableManager.TableLoadType.Tab
        else
            if UseExternalTable and CS.XTableManager.ExternPathSet:Contains(path) then
                return XTableManager.TableLoadType.Tab
            end
            return XTableManager.TableLoadType.Bytes
        end
    else
        return XTableManager.TableLoadType.Pack
    end
end

return router