local XUiTipContent = require("XUi/XUiSocial/PanelTips/XUiTipContent")

local XUiPanelTips = XClass(nil, "XUiPanelTips")

local MAX_ANIMATION_NUMBER = 2
local ANIMATION_DELAY = CS.XGame.ClientConfig:GetFloat("SocialBlackAnimationContentShowTime")
local SECOND = XScheduleManager.SECOND
local HINT_DISABLE_TIME = CS.XGame.ClientConfig:GetInt("SocialHintDisableTime")

function XUiPanelTips:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self.DescList = {}
    self.AnimationGridList = {}
    self.AnimationIndex = 1
    self.View.gameObject:SetActiveEx(false)
    self.Showing = false
end

function XUiPanelTips:InsertDesc(desc)
    self:StopRemoveTipTimer()
    table.insert(self.DescList, desc)
    self:Show()
    self:Refresh()
end

function XUiPanelTips:GetDesc()
    return table.remove(self.DescList, 1)
end

function XUiPanelTips:Refresh()
    local desc = self:GetDesc()
    if not desc or self.Showing then
        self:StartRemoveTipTimer()
        return
    end

    self.Showing = true

    if #self.AnimationGridList < MAX_ANIMATION_NUMBER then
        self:ShowNewTip(desc)
    else
        self:PlayDisableAnimation(function() self:ShowNewTip(desc) end)
    end
end

function XUiPanelTips:ShowNewTip(desc)
    local obj = CS.UnityEngine.GameObject.Instantiate(self.View.gameObject, self.Transform)
    local grid = XUiTipContent.New(obj)
    grid:SetAsLastSibling()
    grid:Refresh(desc)
    grid:SetActive(true)
    table.insert(self.AnimationGridList, grid)
    
    grid:PlayEnableAnimation(function()
        self.Showing = false
        self:Refresh()
    end)
end

function XUiPanelTips:PlayDisableAnimation(cb)
    local obj = self.AnimationGridList[1]
    if obj then
        obj:PlayDisableAnimation(function()
            if (XTool.UObjIsNil(self.GameObject)) or not self.GameObject.activeInHierarchy then
                return
            end
            CS.UnityEngine.GameObject.Destroy(obj:GetGameObject())
            table.remove(self.AnimationGridList, 1)
            
            if cb then
                cb()
            end
        end)
    end
end

function XUiPanelTips:StartRemoveTipTimer()
    self:StopRemoveTipTimer()
    self.RemoveTipTimer = XScheduleManager.ScheduleForever(function()
        if XTool.IsTableEmpty(self.AnimationGridList[1]) then
            self:StopRemoveTipTimer()
            return
        end

        self:PlayDisableAnimation()
    end, HINT_DISABLE_TIME)
end

function XUiPanelTips:StopRemoveTipTimer()
    if self.RemoveTipTimer then
        XScheduleManager.UnSchedule(self.RemoveTipTimer)
        self.RemoveTipTimer = nil
    end
end

function XUiPanelTips:Show()
    self.GameObject.gameObject:SetActiveEx(true)
end

function XUiPanelTips:Hide()
    self:StopRemoveTipTimer()
    self.DescList = {}
    for _, v in pairs(self.AnimationGridList) do
        CS.UnityEngine.GameObject.Destroy(v:GetGameObject())
    end
    self.AnimationGridList = {}
    self.AnimationIndex = 1
    self.GameObject.gameObject:SetActive(false)
end

return XUiPanelTips