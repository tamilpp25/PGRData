local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiGame2048StageDetail : XLuaUi
---@field _Control XGame2048Control
local XUiGame2048StageDetail = XLuaUiManager.Register(XLuaUi, 'UiGame2048StageDetail')
local XUiGridGame2048StageBuff = require('XUi/XUiGame2048/UiGame2048StageDetail/XUiGridGame2048StageBuff')
local XUiGridGame2048StageStar = require('XUi/XUiGame2048/UiGame2048StageDetail/XUiGridGame2048StageStar')

function XUiGame2048StageDetail:OnAwake()
    self.BtnEnter.CallBack = handler(self, self.OnBtnEnerEvent)

    if self.BtnBack then
        self.BtnBack.CallBack = function() 
            self._Control:DispatchEvent(XMVCA.XGame2048.EventIds.EVENT_GAME2048_UNSELECT_STAGE)
        end
    end
end

function XUiGame2048StageDetail:OnStart()
    self._StageId = self._Control:GetCurStageId()
    self._StageType = self._Control:GetStageTypeById(self._StageId)
    self.TxtTitle.text = self._Control:GetStageNameById(self._StageId)
    if self._StageType == XMVCA.XGame2048.EnumConst.StageType.Normal then
        self.PanelRecord.gameObject:SetActiveEx(false)
    elseif self._StageType == XMVCA.XGame2048.EnumConst.StageType.Endless then
        self:InitStageRecord()
    end

    self:InitStageStar()
    self:RefreshStageStar()
    self:InitStageBuff()
    self._ResourcesPanel = XUiPanelAsset.New(self, self.PanelAsset, self._Control:GetCurActivityItemId())
    self._FirstInit = true
end

function XUiGame2048StageDetail:OnEnable()
    local curStageData = self._Control:GetCurStageData()
    local isContinue = curStageData and curStageData.StageId == self._StageId
    self.BtnEnter:SetNameByGroup(0, self._Control:GetClientConfigText('StageDetailBtnEnterLabel', isContinue and 2 or 1))
    
    if self._FirstInit then
        self._FirstInit = false
        return
    end

    self:RefreshStageStar()
    
    if self._StageType == XMVCA.XGame2048.EnumConst.StageType.Endless then
        self:InitStageRecord()
    end
end

function XUiGame2048StageDetail:OnDestroy()
    self._IsDestroy = true
end

function XUiGame2048StageDetail:Close()
    if not self._IsClosing and not self._IsDestroy then
        self.Super.Close(self)
        self._IsClosing = true
    end
end

function XUiGame2048StageDetail:OnBtnEnerEvent()
    local stageData = self._Control:GetCurStageData()

    if stageData then
        if stageData.StageId == self._StageId then
            self._Control:SetCurStageId(self._StageId)
            self:Close()
            XLuaUiManager.Open('UiGame2048Game', stageData)
        else
            XUiManager.DialogTip(CS.XTextManager.GetText("TipTitle"), self._Control:GetClientConfigText('GiveupTips'), nil, nil, function() 
                self._Control:RequestGame2048GiveUp(function()
                    self._Control:RequestGame2048EnterStage(self._StageId, function(res)
                        self._Control:SetCurStageId(self._StageId)
                        self:Close()
                        XLuaUiManager.Open('UiGame2048Game', res.StageContext)
                    end)
                end)
            end)
        end
    else
        self._Control:RequestGame2048EnterStage(self._StageId, function(res)
            self._Control:SetCurStageId(self._StageId)
            self:Close()
            XLuaUiManager.Open('UiGame2048Game', res.StageContext)
        end)
    end
    
end

--region 三星目标显示
function XUiGame2048StageDetail:InitStageStar()
    self._StageStarCtrls = {}
    self.GridStageStar1.gameObject:SetActiveEx(false)
    local descList = self._Control:GetStageStarDescList(self._StageId)
    XUiHelper.RefreshCustomizedList(self.GridStageStar1.transform.parent, self.GridStageStar1, descList and #descList or 0, function(index, go)
        local grid = XUiGridGame2048StageStar.New(go, self)
        grid:Open()
        self._StageStarCtrls[index] = grid
    end)
end

function XUiGame2048StageDetail:RefreshStageStar()
    if not XTool.IsTableEmpty(self._StageStarCtrls) then
        local rewardIds = self._Control:GetStageStarRewardIds(self._StageId)
        local descList = self._Control:GetStageStarDescList(self._StageId)
        for i, v in pairs(self._StageStarCtrls) do
            -- index - 1是服务端数据索引从0开始
            v:Refresh(descList[i], rewardIds[i], self._Control:CheckHasGetStarRewardById(self._StageId, i - 1))
        end
    end
end
--endregion

--region 关卡词缀显示
function XUiGame2048StageDetail:InitStageBuff()
    self._StageBuffCtrls = {}
    self.GridSkill.gameObject:SetActiveEx(false)
    local buffIds = self._Control:GetStageBuffIds(self._StageId)

    XUiHelper.RefreshCustomizedList(self.GridSkill.transform.parent, self.GridSkill, buffIds and #buffIds or 0, function(index, go)
        local grid = XUiGridGame2048StageBuff.New(go, self)
        grid:Open()
        
        local buffIcon = self._Control:GetBuffIcon(buffIds[index])
        local buffDesc = self._Control:GetBuffDesc(buffIds[index])
        
        grid:Refresh(buffIcon, buffDesc)
        self._StageBuffCtrls[index] = grid
    end)

    if XTool.IsTableEmpty(buffIds) then
        self.PanelSkill.gameObject:SetActiveEx(false)
    end
end
--endregion

--region 无限关
function XUiGame2048StageDetail:InitStageRecord()
    self.PanelRecord.gameObject:SetActiveEx(true)
    self.TxtScoreNum.text = self._Control:GetStageMaxScoreById(self._StageId)
end
--endregion

return XUiGame2048StageDetail