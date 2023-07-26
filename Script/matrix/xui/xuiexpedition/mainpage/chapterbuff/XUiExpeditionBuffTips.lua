--虚像地平线词缀展示页面
local XUiExpeditionBuffTips = XLuaUiManager.Register(XLuaUi, "UiExpeditionBuffTips")
local XUiExpeditionBuffTipsItem = require("XUi/XUiExpedition/MainPage/ChapterBuff/XUiExpeditionBuffTipsItem")
function XUiExpeditionBuffTips:OnAwake()
    XTool.InitUiObject(self)
    self.GridBuff.gameObject:SetActiveEx(false)
    self:RegisterUiButtonEvent()
end

function XUiExpeditionBuffTips:OnStart(type, dataList)
    self.Type = type
    self.DataList = dataList
    self.StageTitle.gameObject:SetActiveEx(self.Type == XDataCenter.ExpeditionManager.BuffTipsType.StageBuff)
    self.GlobleTitle.gameObject:SetActiveEx(self.Type == XDataCenter.ExpeditionManager.BuffTipsType.GlobalBuff)
    if self.Type == XDataCenter.ExpeditionManager.BuffTipsType.GlobalBuff then
        self:RefreshGlobalType()
    elseif self.Type == XDataCenter.ExpeditionManager.BuffTipsType.StageBuff then
        self:RefreshStageType()
    elseif self.Type == XDataCenter.ExpeditionManager.BuffTipsType.Skill then
        self:RefreshSkillType()
    end
end

function XUiExpeditionBuffTips:RegisterUiButtonEvent()
    self.BtnClose.CallBack = function() self:OnBtnCloseClick() end
end

function XUiExpeditionBuffTips:OnBtnCloseClick()
    self:Close()
end

function XUiExpeditionBuffTips:RefreshGlobalType()
    for _, globalCfg in pairs(self.DataList) do
        local prefab = CS.UnityEngine.Object.Instantiate(self.GridBuff.gameObject)
        prefab.transform:SetParent(self.PanelContent.transform, false)
        local tipItem = XUiExpeditionBuffTipsItem.New(prefab, self)
        local tipData = {
            Type = self.Type,
            Cfg = globalCfg,
            }
        tipItem:RefreshData(tipData)
        tipItem.GameObject:SetActiveEx(true)
    end
end

function XUiExpeditionBuffTips:RefreshStageType()
    for _, stageBuffCfg in pairs(self.DataList) do
        local prefab = CS.UnityEngine.Object.Instantiate(self.GridBuff.gameObject)
        prefab.transform:SetParent(self.PanelContent.transform, false)
        local tipItem = XUiExpeditionBuffTipsItem.New(prefab, self)
        local tipData = {
            Type = self.Type,
            Cfg = stageBuffCfg,
        }
        tipItem:RefreshData(tipData)
        tipItem.GameObject:SetActiveEx(true)
    end
end

function XUiExpeditionBuffTips:RefreshSkillType()
    for _, skillInfo in pairs(self.DataList) do
        local prefab = CS.UnityEngine.Object.Instantiate(self.GridBuff.gameObject)
        prefab.transform:SetParent(self.PanelContent.transform, false)
        local tipItem = XUiExpeditionBuffTipsItem.New(prefab, self)
        local tipData = {
            Type = self.Type,
            Cfg = skillInfo,
        }
        tipItem:RefreshData(tipData)
        tipItem.GameObject:SetActiveEx(true)
    end
end