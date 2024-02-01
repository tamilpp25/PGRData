---@class XUiFangKuaiChapterDetail : XLuaUi 大方块关卡详情
---@field _Control XFangKuaiControl
local XUiFangKuaiChapterDetail = XLuaUiManager.Register(XLuaUi, "UiFangKuaiChapterDetail")

function XUiFangKuaiChapterDetail:OnAwake()
    self:RegisterClickEvent(self.BtnChange, self.OnClickChange)
    self:RegisterClickEvent(self.BtnTongBlack, self.OnClickTongBlack)
    self:RegisterClickEvent(self.BtnExchangeEmpty, self.OnClickExchangeEmpty)
    self:RegisterClickEvent(self.BtnCloseExchange, self.OnClickExchangeEmpty)
    self:BindHelpBtn(self.BtnHelp, self._Control:GetHelpId())
end

function XUiFangKuaiChapterDetail:OnStart(stageId)
    self._StageId = stageId
    self._IsNormal = self._Control:IsStageNormal(stageId)
    self._StageConfig = self._Control:GetStageConfig(stageId)
    self._CurNpcId = self._Control:GetCurShowNpcId()
    self._Control:SaveEnterStageRecord(stageId)

    self:InitSceneRoot()
    self:InitCompnent()
    self:InitSelectNpc()
    self:UpdateEnemy()
    self:UpdatePlayer()
    self:HideOrShowExchange(false)

    self.EndTime = self._Control:GetActivityGameEndTime()
    self:SetAutoCloseInfo(self.EndTime, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end)
end

function XUiFangKuaiChapterDetail:OnEnable()
    self.Super.OnEnable(self)
end

function XUiFangKuaiChapterDetail:OnDestroy()

end

function XUiFangKuaiChapterDetail:InitCompnent()
    self._TopController = XUiHelper.NewPanelTopControl(self, self.TopControlWhite)
end

function XUiFangKuaiChapterDetail:InitSelectNpc()
    local btns = {}
    local curSelect = 1
    self._NpcList = self._Control:GetAllPlayerNpc()
    XUiHelper.RefreshCustomizedList(self.Content.transform, self.GridCharacterNew, #self._NpcList, function(index, grid)
        local npc = self._NpcList[index]
        local favorabilityLv = self._Control:GetFavorLevelColor(npc.CharacterId, npc.FavorLv)
        local isSelected = npc.Config.Id == self._CurNpcId
        local uiObject = {}
        XUiHelper.InitUiClass(uiObject, grid)
        uiObject.RImgHeadIcon:SetRawImage(npc.Config.HeadIcon)
        uiObject.RImgSelectHeadIcon:SetRawImage(npc.Config.HeadIcon)
        uiObject.TxtRobotName.text = npc.Config.Name
        uiObject.TxtSelectRobotName.text = npc.Config.Name
        uiObject.TxtRobotTradeName.text = npc.Config.TradeName
        uiObject.TxtSelectRobotTradeName.text = npc.Config.TradeName
        uiObject.TxtLv.text = npc.FavorLv
        uiObject.TxtFavorabilityLv.text = favorabilityLv
        uiObject.TxtSelectFavorabilityLv.text = favorabilityLv
        uiObject.PanelSelected.gameObject:SetActiveEx(isSelected)
        uiObject.PanelNormal.gameObject:SetActiveEx(not isSelected)
        self:SetUiSprite(uiObject.ImgHeart, self._Control:GetFavorLevelIcon(npc.FavorLv))
        table.insert(btns, uiObject.GridCharacterNew)
        if isSelected then
            curSelect = index
        end
    end)
    self.Content:Init(btns, function(index)
        self:OnTabsClick(index)
    end)
    self.Content:SelectIndex(curSelect)
end

function XUiFangKuaiChapterDetail:InitSceneRoot()
    local panelModel = self.UiModelGo.transform:FindTransform("PanelModel")
    self._UiCamNearMain = self.UiModelGo.transform:FindTransform("UiCamNearMain")
    self._UiCamNearChange = self.UiModelGo.transform:FindTransform("UiCamNearPanelExchange")
    self._UiCamFarPanelExchange = self.UiModelGo.transform:FindTransform("UiCamFarPanelExchange")
    ---@type XUiPanelRoleModel
    self._RoleModelPanel = require("XUi/XUiCharacter/XUiPanelRoleModel").New(panelModel, self.Name, nil, true, nil, true)
end

function XUiFangKuaiChapterDetail:UpdateEnemy()
    local stageConfig = self._Control:GetStageConfig(self._StageId)
    self.RImgBoss:SetRawImage(stageConfig.HeadIcon)
    self.TxtNum.text = self._IsNormal and self._StageConfig.MaxRound or ""
    self.TxtDetail.text = self._StageConfig.Desc
    self.TxtRound.gameObject:SetActiveEx(self._IsNormal)
    self.TxtNoLimit.gameObject:SetActiveEx(not self._IsNormal)
    self.TxtTitle.text = stageConfig.Name
    self.TxtName.text = stageConfig.BossName

    local items = self._Control:GetStageShowItems(self._StageId)
    XUiHelper.RefreshCustomizedList(self.ListFangKuai, self.GridFangKuai, #items, function(index, grid)
        local uiObject = {}
        XUiHelper.InitUiClass(uiObject, grid)
        uiObject.RImgIcon:SetRawImage(items[index].Icon)
        XUiHelper.RegisterClickEvent(uiObject, uiObject.RImgIcon.transform, function()
            self:OnClickItem(items[index].Id)
        end)
    end)
end

function XUiFangKuaiChapterDetail:UpdatePlayer()
    local npcAction = self._Control:GetNpcActionConfig(self._CurNpcId)
    self._RoleModelPanel:UpdateCuteModelByModelName(nil, nil, nil, nil, nil, npcAction.Model, nil, true, nil, nil, true)
end

function XUiFangKuaiChapterDetail:HideOrShowExchange(isShow)
    self.PaneExchange.gameObject:SetActiveEx(isShow)
    self.PanelChapterDetail.gameObject:SetActiveEx(not isShow)
    self.BtnTongBlack.gameObject:SetActiveEx(not isShow)
    self._UiCamNearMain.gameObject:SetActiveEx(not isShow)
    self._UiCamNearChange.gameObject:SetActiveEx(isShow)
    self._UiCamFarPanelExchange.gameObject:SetActiveEx(isShow)
    self.BtnChange.gameObject:SetActiveEx(not isShow)
end

function XUiFangKuaiChapterDetail:OnTabsClick(index)
    self._CurNpc = self._NpcList[index]
    self._CurNpcId = self._CurNpc.Config.Id
    self:UpdatePlayer()

    local key = string.format("FangKuaiNpcId_%s_%s", XPlayer.Id, self._Control:GetActivityId())
    XSaveTool.SaveData(key, self._CurNpcId)
end

function XUiFangKuaiChapterDetail:OnClickChange()
    self:HideOrShowExchange(true)
end

function XUiFangKuaiChapterDetail:OnClickExchangeEmpty()
    self:HideOrShowExchange(false)
end

function XUiFangKuaiChapterDetail:OnClickTongBlack()
    self._Control:FangKuaiStageStartRequest(self._StageId, function()
        self:OpenFightPanel()
    end)
end

function XUiFangKuaiChapterDetail:OpenFightPanel()
    self._Control:EnterGame(self._StageId, true)
end

function XUiFangKuaiChapterDetail:OnClickItem(itemId)
    XLuaUiManager.Open("UiFangKuaiPropDetail", itemId)
end

return XUiFangKuaiChapterDetail