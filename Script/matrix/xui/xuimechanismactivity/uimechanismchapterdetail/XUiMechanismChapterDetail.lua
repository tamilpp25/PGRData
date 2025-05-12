local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
---@class XUiMechanismChapterDetail
---@field _Control XMechanismActivityControl
local XUiMechanismChapterDetail = XLuaUiManager.Register(XLuaUi, 'UiMechanismChapterDetail')
local XUiGridStageStar = require('XUi/XUiMechanismActivity/UiMechanismChapterDetail/XUiGridStageStar')
local XUiGridStageAffix = require('XUi/XUiMechanismActivity/UiMechanismChapterDetail/XUiGridStageAffix')

function XUiMechanismChapterDetail:OnAwake()
    self.BtnEnter.CallBack = handler(self, self.OnBtnEnerEvent)
    self.BtnClose.CallBack = handler(self, self.Close)
end

function XUiMechanismChapterDetail:OnStart(chapterId, stageId, stageIndex)
    self._ChapterId = chapterId
    self._StageId = stageId
    self._StageIndex = stageIndex
    
    self.TxtTopTitle.text = XUiHelper.FormatText(self._Control:GetMechanismClientConfigStr('StageDetailNameFormat'), self._Control:GetStageNameById(self._StageId), string.format('%02d', self._StageIndex))
    self:InitStageStar()
    self:InitStageAffix()
    self._ResourcesPanel = XUiPanelAsset.New(self, self.PanelAsset, self._Control:GetCoinItemByActivityId(self._Control:GetCurActivityId()))
    self._Control:SetSelectStageIndex(self._ChapterId, self._StageIndex)
end


function XUiMechanismChapterDetail:OnBtnEnerEvent()
    XLuaUiManager.Open("UiBattleRoleRoom",self._StageId,self._Control:GetTeamDataByChapterId(self._ChapterId),require('XUi/XUiMechanismActivity/UiMechanismBattleRoleRoom/XUiMechanismBattleRoleRoom'))
end

--region 三星目标显示
function XUiMechanismChapterDetail:InitStageStar()
    self._StageStarCtrls = {}
    self.GridStageStar1.gameObject:SetActiveEx(false)
    local rewardIds = self._Control:GetStageStarRewardIds(self._StageId)
    local descList = self._Control:GetStageStarDescList(self._StageId)
    for i, desc in ipairs(descList) do
        local clone = CS.UnityEngine.GameObject.Instantiate(self.GridStageStar1, self.GridStageStar1.transform.parent)
        local grid = XUiGridStageStar.New(clone, self)
        grid:Open()
        grid:Refresh(desc, rewardIds[i], self._Control:CheckHasGetStarRewardById(self._StageId, i))
        self._StageStarCtrls[i] = grid
    end
end
--endregion

--region 关卡词缀显示
function XUiMechanismChapterDetail:InitStageAffix()
    self._StageAffixCtrls = {}
    self.GridAffix.gameObject:SetActiveEx(false)
    local affixIcons = self._Control:GetStageAffixIcons(self._StageId)
    local affixDesc = self._Control:GetStageAffixDesc(self._StageId)
    for i, desc in ipairs(affixDesc) do
        local clone = CS.UnityEngine.GameObject.Instantiate(self.GridAffix, self.GridAffix.transform.parent)
        local grid = XUiGridStageAffix.New(clone, self)
        grid:Open()
        grid:Refresh(affixIcons[i], affixDesc[i])
        self._StageAffixCtrls[i] = grid
    end
end
--endregion

return XUiMechanismChapterDetail