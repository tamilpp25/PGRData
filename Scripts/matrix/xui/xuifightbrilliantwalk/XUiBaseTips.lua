local XUiBaseTips = XClass(nil, "XUiBaseTips")

local CSXFightIntStringMapManagerTryGetString = CS.XFightIntStringMapManager.TryGetString
local CSXTextManagerFormatString = CS.XTextManager.FormatString

function XUiBaseTips:Ctor(ui)
    self.GameObject = ui.gameObject
    self.RectTransform = self.GameObject:GetComponent("RectTransform")
    XTool.InitUiObjectByUi(self, ui)
    self.Offset = Vector2(0, 0)     --骨骼点偏移
    self.RecodeTipTextIndex = 1     --有多个文本框时，缓存当前使用的文本框下标
    self.CSXRLManagerCamera = CS.XRLManager.Camera
    self.CSWorldToViewPoint = CS.XFightUiManager.WorldToViewPoint
    self.RectTransform.anchorMax = Vector2(0, 0)
    self.RectTransform.anchorMin = Vector2(0, 0)
    self:InitVarDic()
    self.GameObject:SetActiveEx(true)
end

function XUiBaseTips:InitVarDic()
    local MAX_VAR_COUNT_PER_LINE = 6
    self.VarDic = {}
    for i = 1, MAX_VAR_COUNT_PER_LINE do
        self.VarDic[i] = 0
    end
end

function XUiBaseTips:Init(npc, jointName, xOffset, yOffset, styleType)
    local fight = CS.XFight.Instance
    if not fight then
        return
    end

    self.StyleType = styleType
    if string.IsNilOrEmpty(jointName) then
        jointName = CS.XStealthManager.XTargetIndicator.NameMarkCase
    end
    
    self.FollowNpc = npc
    self.FollowNode = self.FollowNpc.RLNpc:GetJoint(jointName)
    self.Offset = Vector2(xOffset, yOffset)
end

function XUiBaseTips:SetDesc(textIndex, tipTextId, varIndex, value)
    local succeed, text = CSXFightIntStringMapManagerTryGetString(tipTextId)
    if not succeed then
        return
    end
    if varIndex > 0 then
        self.VarDic[varIndex] = value
    end
    self.Desc.text = CSXTextManagerFormatString(text, table.unpack(self.VarDic))
end

function XUiBaseTips:SetDescValue(index, value)
    self.VarDic[index] = value
    if self.Text then
        self.Desc.text = CSXTextManagerFormatString(self.Text, table.unpack(self.VarDic))
    end
end

function XUiBaseTips:SetRecodeTipTextIndex(index)
    self.RecodeTipTextIndex = index
end

function XUiBaseTips:GetRecodeTipTextIndex()
    return self.RecodeTipTextIndex
end

function XUiBaseTips:Update()
    if not self.FollowNpc then
        return false
    end
    
    if not self.FollowNpc.IsActivate then
        self.GameObject:SetActiveEx(false)
    else
        local pos = self.FollowNode.position
        if self.CSXRLManagerCamera:CheckInView(pos) then
            local viewPoint = self.CSWorldToViewPoint(pos)
            self.RectTransform.anchoredPosition = Vector2(viewPoint.x, viewPoint.y) + self.Offset
            self.GameObject:SetActiveEx(true)
        else
            self.GameObject:SetActiveEx(false)
        end
    end
    
    return true
end

function XUiBaseTips:OnDestroy()
    XUiHelper.Destroy(self.GameObject)
end

function XUiBaseTips:GetStyleType()
    return self.StyleType
end

function XUiBaseTips:SetConfigId(configId)
    self.ConfigId = configId
end

function XUiBaseTips:GetConfigId()
    return self.ConfigId
end

return XUiBaseTips