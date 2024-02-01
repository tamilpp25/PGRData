XQualityManagerCreator = function()
    local XQualityManager = {}

    local CSXQualityManager = CS.XQualityManager.Instance

    local PlayerPrefs = CS.UnityEngine.PlayerPrefs

    local VersionQualityKey = "v2.9-QualityCustom"

    local NeecCheckVersions =  {
        "2.9.0",
        "2.11.0"
    }

    XQualityManager.Init = function()
        if XDataCenter.UiPcManager.IsPc() then
            -- 仅对移动端生效
            return
        end
        -- 限制在移动端且2.9版本检查 v2.11版本需要再检查一次
        -- 在Editor模式下总是进行检查
        local needCheck = true
        if not CS.UnityEngine.Application.platform == CS.UnityEngine.RuntimePlatform.WindowsEditor then
            if NeecCheckVersions[CS.XRemoteConfig.ApplicationVersion] then
                needCheck = true
            else 
                needCheck = false
            end
        end
        if not needCheck then
            return
        end
        local tag = PlayerPrefs.GetInt(VersionQualityKey, 0)
        if not tag or tag == 0 then
            -- 将画质设置选择调整到Custom
            -- 取得原本的设置, 然后应用到Custom上
            CS.XLog.Debug("画质分级有更新, 将旧设置更新到自定义档位上");

            local prevLevel = CSXQualityManager:GetCurQualitySettings()
            if prevLevel ~= 0 then
                local cQuality = CSXQualityManager:GetQualitySettings(prevLevel)
                CSXQualityManager:SetQualitySettings(0, cQuality)
                PlayerPrefs.SetInt(VersionQualityKey, 1)
            end
        end
    end

    XQualityManager.Init()
    return XQualityManager
end