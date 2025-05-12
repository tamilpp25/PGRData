local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
---@class XUiFubenBabelTowerRank: XLuaUi
local XUiFubenBabelTowerRank = XLuaUiManager.Register(XLuaUi, "UiFubenBabelTowerRank")
local XUiBabelTowerRankInfo = require("XUi/XUiFubenBabelTower/XUiBabelTowerRankInfo")


function XUiFubenBabelTowerRank:OnAwake()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self:BindHelpBtn(self.BtnHelp, "BabelTowerRank")
    ---@type XUiBabelTowerRankInfo
    self.BabelTowerRankInfo = XUiBabelTowerRankInfo.New(self.PanelBossRankInfo, self)
    self.ActivityType = nil
end

function XUiFubenBabelTowerRank:OnStart(activityType)
    self.ActivityType = activityType
    self.BabelTowerRankInfo:SetActivityType(activityType)
    self.BabelTowerRankInfo:InitRankTag()
    -- 开启自动关闭检查
    self.EndTime = XDataCenter.FubenBabelTowerManager.GetEndTime(activityType)
    self:SetAutoCloseInfo(self.EndTime, function(isClose)
        if isClose then
            XDataCenter.FubenBabelTowerManager.HandleActivityEndTime(activityType)
        else
            self:RefreshTime()
        end
    end)
end

function XUiFubenBabelTowerRank:OnEnable()
    self.Super.OnEnable(self)
    self:RefreshTime()
    self.BabelTowerRankInfo:DefaultSelectIndex()
    self:CheckActivityStatus()
end

function XUiFubenBabelTowerRank:CheckActivityStatus()
    if not XLuaUiManager.IsUiShow("UiFubenBabelTowerRank") then
        return
    end
    XDataCenter.FubenBabelTowerManager.HandleActivityEndTime(self.ActivityType)
end

--- 刷新时间
function XUiFubenBabelTowerRank:RefreshTime()
    local leftTime = self.EndTime - XTime.GetServerNowTimestamp()
    if leftTime <= 0 then
        leftTime = 0
    end
    local leftTimeDesc = XUiHelper.GetText("BabelTowerRankReset")
    local timeStr = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
    self.BabelTowerRankInfo:UpdateCurTime(string.format(leftTimeDesc, timeStr))
    if leftTime > 0 then
        self.BabelTowerRankInfo:UpdateRefreshTime()
    end
end

function XUiFubenBabelTowerRank:OnBtnBackClick()
    self:Close()
end

function XUiFubenBabelTowerRank:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

return XUiFubenBabelTowerRank
