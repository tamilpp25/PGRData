--虚像地平线招募公示
local XUiExpeditionPublicity = XLuaUiManager.Register(XLuaUi, "UiExpeditionPublicity")
local XPublicityTitle = require("XUi/XUiExpedition/Recruit/XUiExpeditionPublicityTitle")
local XDrawPR = require("XUi/XUiExpedition/Recruit/XUiExpeditionDrawPR")

function XUiExpeditionPublicity:OnAwake()
    XTool.InitUiObject(self)
    self.BtnClose.CallBack = function() self:OnBtnCloseClick() end
    self:InitRecruitInfo()
    self:InitPanelDrawPR()
end
--================
--初始化招募信息
--================
function XUiExpeditionPublicity:InitRecruitInfo()
    self.TxtRecruitTime.text = XDataCenter.ExpeditionManager.GetRecruitNum()
    self.TxtLevel.text = XDataCenter.ExpeditionManager.GetRecruitLevel()
end
--================
--初始化招募表
--================
function XUiExpeditionPublicity:InitPanelDrawPR()
    self:InitTitle()
    self:InitDrawPR()
end
--================
--初始化招募表头
--================
function XUiExpeditionPublicity:InitTitle()
    self.GridTitle.gameObject:SetActiveEx(false)
    local drawStarCfg = XExpeditionConfig.GetDrawRankConfig()
    for i = 1, #drawStarCfg do
        if drawStarCfg[i] then
            local prefab = CS.UnityEngine.Object.Instantiate(self.GridTitle.gameObject)
            prefab.transform:SetParent(self.TitleContent, false)
            prefab.gameObject:SetActiveEx(true)
            local title = XPublicityTitle.New(prefab.gameObject)
            title:RefreshTitle(drawStarCfg[i].Rank)
        end
    end
    self:AddNeedTimesTitle()
end
--================
--添加需求招募次数表头
--================
function XUiExpeditionPublicity:AddNeedTimesTitle()
    local prefab = CS.UnityEngine.Object.Instantiate(self.GridTitle.gameObject)
    prefab.transform:SetParent(self.TitleContent, false)
    prefab.gameObject:SetActiveEx(true)
    local title = XPublicityTitle.New(prefab.gameObject)
    title:SetTitle(CS.XTextManager.GetText("ExpeditionDrawPRRecruitTimes"))
end
--================
--初始化招募概率条目
--================
function XUiExpeditionPublicity:InitDrawPR()
    self.GridPercents.gameObject:SetActiveEx(false)
    local drawPRCfg = XExpeditionConfig.GetDrawPRConfig()
    for i = 1, #drawPRCfg do
        if drawPRCfg[i] then
            local prefab = CS.UnityEngine.Object.Instantiate(self.GridPercents.gameObject)
            prefab.transform:SetParent(self.DrawPRContent, false)
            prefab.gameObject:SetActiveEx(true)
            local drawPR = XDrawPR.New(prefab.gameObject)
            drawPR:RefreshData(drawPRCfg[i])
        end
    end
end

function XUiExpeditionPublicity:OnGetEvents()
    return { XEventId.EVENT_ACTIVITY_ON_RESET }
end

function XUiExpeditionPublicity:OnNotify(evt, ...)
    local args = { ... }
    if evt == XEventId.EVENT_ACTIVITY_ON_RESET then
        if args[1] ~= XDataCenter.FubenManager.StageType.Expedition then return end
        self:OnActivityReset()
    end
end

function XUiExpeditionPublicity:OnActivityReset()
    XLuaUiManager.RunMain()
    XUiManager.TipMsg(CS.XTextManager.GetText("ExpeditionOnClose"))
end

function XUiExpeditionPublicity:OnBtnCloseClick()
    self:Close()
end