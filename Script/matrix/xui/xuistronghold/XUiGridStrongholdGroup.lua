local XUiGridStrongholdBuff = require("XUi/XUiStronghold/XUiGridStrongholdBuff")

local handler = handler
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

local XUiGridStrongholdGroup = XClass(nil, "XUiGridStrongholdGroup")

function XUiGridStrongholdGroup:Ctor(ui, index, clickStageCb, skipCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.BuffGrids = {}
    self.Index = index
    self.ClickStageCb = clickStageCb
    self.SkipCb = skipCb

    self.PanelYzz = self.Transform:FindTransform("PanelYzz")
    XTool.InitUiObject(self)

    self:SetSelect(false)

    if self.BtnClick then self.BtnClick.CallBack = handler(self, self.OnClickBtnClick) end
end

function XUiGridStrongholdGroup:Refresh(groupId)
    self.GroupId = groupId

    if self.RImgBg then
        local icon = XStrongholdConfigs.GetGroupIconBg(groupId)
        if icon then
            self.RImgBg:SetRawImage(icon)
        end
    end

    if self.RImgBossIcon then
        local stageId = XDataCenter.StrongholdManager.GetGroupStageId(groupId, 1)
        local icon = XStrongholdConfigs.GetGroupBossIcon(groupId, stageId)
        if icon then
            self.RImgBossIcon:SetRawImage(icon)
        end
    end

    if self.TxtName then
        self.TxtName.text = XStrongholdConfigs.GetGroupName(groupId)
    end

    if self.TxtOrder then
        local name = XStrongholdConfigs.GetGroupOrder(groupId)
        self.TxtOrder.text = name
    end

    if self.TxtStageNum then
        local stageNum = XDataCenter.StrongholdManager.GetGroupStageNum(groupId)
        self.TxtStageNum.text = "x" .. stageNum
    end

    if self.CommonFuBenClear then
        local isFinished = XDataCenter.StrongholdManager.IsGroupFinished(groupId)
        self.CommonFuBenClear.gameObject:SetActiveEx(isFinished)
    end

    if self.PanelBuff then
        self:RefreshBuffs()
    end

    if self.PanelYzz then
        local isFinished = XDataCenter.StrongholdManager.CheckGroupHasFinishedStage(groupId)
        self.PanelYzz.gameObject:SetActiveEx(isFinished)
    end

    if self.ImgMoppingup then
        local isAutoFight = XDataCenter.StrongholdManager.IsAutoFightByGroupId(groupId)
        self.ImgMoppingup.gameObject:SetActiveEx(isAutoFight)
    end
end

function XUiGridStrongholdGroup:RefreshBuffs()
    local groupId = self.GroupId

    local buffIds = XDataCenter.StrongholdManager.GetGroupBossBuffIds(groupId)
    if self.PanelBuff.gameObject then
        self.PanelBuff.gameObject:SetActiveEx(#buffIds > 0)
    end

    local isBossBuff = true
    for index, buffId in ipairs(buffIds) do
        local grid = self.BuffGrids[index]
        if not grid then
            local go = index == 1 and self.GridBuff or CSUnityEngineObjectInstantiate(self.GridBuff, self.PanelBuff)
            grid = XUiGridStrongholdBuff.New(go, nil, self.SkipCb)
            self.BuffGrids[index] = grid
        end

        local showEffect = true


        grid:Refresh(buffId, isBossBuff, showEffect)
        grid.GameObject:SetActiveEx(true)
    end

    for index = #buffIds + 1, #self.BuffGrids do
        local grid = self.BuffGrids[index]
        if grid then
            grid.GameObject:SetActiveEx(false)
        end
    end
end

function XUiGridStrongholdGroup:SetSelect(value)
    if self.ImgSelect then
        self.ImgSelect.gameObject:SetActiveEx(value)
    end
end

function XUiGridStrongholdGroup:OnClickBtnClick()
    if self.ClickStageCb then self.ClickStageCb(self.Index) end
end

return XUiGridStrongholdGroup