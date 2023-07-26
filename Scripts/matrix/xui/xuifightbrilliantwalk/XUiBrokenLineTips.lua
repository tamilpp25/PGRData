local XUiBaseTips = require("XUi/XUiFightBrilliantwalk/XUiBaseTips")
local XUiBrokenLineTips = XClass(XUiBaseTips, "XUiBrokenLineTips")

local LowerLeft = CS.UnityEngine.TextAnchor.LowerLeft
local LowerRight = CS.UnityEngine.TextAnchor.LowerRight
local START_POINT_OFFSET_X_PERCENT = 0.25
local START_POINT_OFFSET_Y_PERCENT = 0.45
local OFFSET_RATIO = 200    --链接开始点偏移值转世界坐标的比值

function XUiBrokenLineTips:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
    self.CSRLManager = CS.XFight.Instance.RLManager
    self.AimTipsList.gameObject:SetActiveEx(false)
    self.TipsDic = {}
    self.LockPanel.localPosition = Vector3.zero
    self.AimTipsOriginPosX = self.FightBrilliantwalkAimTips.transform.localPosition.x
end

function XUiBrokenLineTips:SetLink(effectName)
    if not self.CSRLManager then
        return
    end
    self:RemoveLink()
    self.RLLink = self.CSRLManager:LinkEffect(effectName, self.StartPoint.transform, self.LineEndIcon.transform, nil, nil, false, Vector3.zero, Vector3.zero, CS.XDirectLink.TrajectoryType.Broken)
end

--endX, endY：相对骨骼点的链接终点位置
function XUiBrokenLineTips:Init(npc, jointName, xOffset, yOffset, styleType, endX, endY, effectName)
    self.Super.Init(self, npc, jointName, xOffset, yOffset, styleType)
    self.EndPos = Vector2(endX, endY)
    
    --检查是否需要左右翻转
    local isFlip = endX > 0
    local scaleX = isFlip and -1 or 1
    local scale = Vector3(scaleX, 1, 1)
    self.HeadIcon.transform.localScale = scale
    self.LineEndPanel.transform.localScale = scale
    self.FightBrilliantwalkAimTips.ChildAlignment = isFlip and LowerLeft or LowerRight
    --链接开始点的偏移
    local xDirection = isFlip and 1 or -1
    local yDirection = endY > 0 and 1 or -1
    self.StartPoint.localPosition = Vector3(self.StartPoint.rect.width * START_POINT_OFFSET_X_PERCENT * xDirection, 
            self.StartPoint.rect.height * START_POINT_OFFSET_Y_PERCENT * yDirection, 0)
    --创建折线链接
    self:SetLink(effectName)
    self.IsFlip = isFlip
end

function XUiBrokenLineTips:Update()
    if not self.FollowNpc then
        return
    end

    if not self.FollowNpc.IsActivate then
        self.GameObject:SetActiveEx(false)
    else
        local followNodeOffset = Vector3(self.Offset.x / OFFSET_RATIO, self.Offset.y / OFFSET_RATIO)
        local pos = self.FollowNode.position + followNodeOffset
        if self.CSXRLManagerCamera:CheckInView(pos) then
            local viewPoint = self.CSWorldToViewPoint(pos)
            local viewPointToVector2 = Vector2(viewPoint.x, viewPoint.y)
            self.Panel.anchoredPosition = viewPointToVector2 + self.EndPos
            self.LockPanel.anchoredPosition = viewPointToVector2
            self.GameObject:SetActiveEx(true)
        else
            self.GameObject:SetActiveEx(false)
        end
    end
end

function XUiBrokenLineTips:GetTips(textIndex)
    local tips = self.TipsDic[textIndex]
    if not tips then
        tips = XUiBaseTips.New(XUiHelper.Instantiate(self.AimTipsList, self.FightBrilliantwalkAimTips.transform))
        self.TipsDic[textIndex] = tips
    end
    return tips
end

function XUiBrokenLineTips:SetDesc(textIndex, tipTextId, varIndex, value)
    local tips = self:GetTips(textIndex)
    tips:SetDesc(textIndex, tipTextId, varIndex, value)
    XScheduleManager.ScheduleOnce(function()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        self:UpdateDescPos()
    end, 0)
end

function XUiBrokenLineTips:UpdateDescPos()
    local position
    if self.EndPos.x <= 0 then
        position = Vector3(self.AimTipsOriginPosX, self.FightBrilliantwalkAimTips.transform.localPosition.y, 0)
    else
        local endPanelWidth = self.LineEndPanel.transform:GetComponent("RectTransform").rect.width
        local tipsWidth = self.FightBrilliantwalkAimTips.transform:GetComponent("RectTransform").rect.width
        local posX = self.AimTipsOriginPosX + tipsWidth - endPanelWidth
        position = Vector3(posX, self.FightBrilliantwalkAimTips.transform.localPosition.y, 0)
    end
    
    self.FightBrilliantwalkAimTips.transform.localPosition = position
    self.FightBrilliantwalkAimTips.enabled = false
    self.FightBrilliantwalkAimTips.enabled = true
end

function XUiBrokenLineTips:OnDestroy()
    self.Super.OnDestroy(self)
    self:RemoveLink()
end

function XUiBrokenLineTips:RemoveLink()
    if self.RLLink and self.CSRLManager then
        self.CSRLManager:RemoveEntityImmediately(self.RLLink)
        self.RLLink = nil
    end
end

return XUiBrokenLineTips