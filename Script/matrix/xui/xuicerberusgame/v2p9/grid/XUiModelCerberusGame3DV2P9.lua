local XUiModelCerberusGame3D = require("XUi/XUiCerberusGame/Grid/XUiModelCerberusGame3D")
---@class XUiModelCerberusGame3DV2P9:XUiModelCerberusGame3D
local XUiModelCerberusGame3DV2P9 = XClass(XUiModelCerberusGame3D, "XUiModelCerberusGame3DV2P9")

function XUiModelCerberusGame3DV2P9:InitModelAndPosInfo()
    self.ModelDic = 
    {
        [1] = "R2NuoketiMd010031",
        [2] = "R3WeilaMd010031",
        [3] = "R3TwentyoneMd010031",
    }
    self.CameraPos = 
    {
        [1] = 5.7,
        [2] = 0,
        [3] = 12.4,
    }
    self.TrackMoveDuration = 3
    self.TrackMoveSpeed = 0.2
    self.RoundLength = 18.2
end

function XUiModelCerberusGame3DV2P9:SetTargetModelUnSelect(index)
    local modelKey = self.ModelDic[index]
    local animator = self[modelKey]
    if not animator then
        return
    end

    local stateInfo = animator:GetCurrentAnimatorStateInfo(0)
    if stateInfo:IsName("Attack26") or stateInfo:IsName("Attack27") then
        animator:SetTrigger("DoPlayBack")
    end
end

function XUiModelCerberusGame3DV2P9:SetTargerModelSelect(index)
    local modelKey = self.ModelDic[index]
    local animator = self[modelKey]
    if not animator then
        return
    end

    local stateInfo = animator:GetCurrentAnimatorStateInfo(0)
    if stateInfo:IsName("Attack26") or stateInfo:IsName("Attack27") then
        return
    end
    animator:SetTrigger("DoPlaySelect")
end

return XUiModelCerberusGame3DV2P9