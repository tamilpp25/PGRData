local XUiGridStageStar = require("XUi/XUiFubenMainLineDetail/XUiGridStageStar")
--- 超难关关卡详情页
---@class XUiActivityBossSinglePopupStageDetail: XLuaUi
local XUiActivityBossSinglePopupStageDetail = XLuaUiManager.Register(XLuaUi, 'UiActivityBossSinglePopupStageDetail')
local StarDescCount = 3
local CsXTextManager = CS.XTextManager

function XUiActivityBossSinglePopupStageDetail:OnAwake()
    self.BtnTanchuangCloseBig.CallBack = handler(self, self.Close)
    self.BtnTanchuangClose.CallBack = handler(self, self.Close)
    self.BtnNote.CallBack = handler(self, self.OnBtnNoteClick)
    self.BtnEnter.CallBack = handler(self, self.OnBtnEnterClick)
    
    self:InitStarDesc()
end

function XUiActivityBossSinglePopupStageDetail:OnStart(stageId)
    self.StageId = stageId
    self:InitStageDetailInfo(stageId)
end

--初始化详细信息面板的挑战目标
function XUiActivityBossSinglePopupStageDetail:InitStarDesc()
    self.GridStarList = {}
    for i = 1, StarDescCount do
        local ui = self["GridStageStar" .. i]
        ui.gameObject:SetActiveEx(true)
        local grid = XUiGridStageStar.New(ui)
        self.GridStarList[i] = grid
    end
end

--初始化副本的详细信息
function XUiActivityBossSinglePopupStageDetail:InitStageDetailInfo(stageId)
    self.TxtTitle.text = XFubenActivityBossSingleConfigs.GetBossChallengeDetailTitle(stageId)
    
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
    local starsMap = XDataCenter.FubenActivityBossSingleManager.GetStageStarMap(stageId)

    --刷新消耗数量
    self.TxtATNums.text = XDataCenter.FubenManager.GetRequireActionPoint(stageId)
    
    for i = 1, StarDescCount do
        self.GridStarList[i]:Refresh(stageCfg.StarDesc[i], starsMap[i])
    end
end

--点击描述按钮显示的注意事项
function XUiActivityBossSinglePopupStageDetail:OnBtnNoteClick()
    local attentionDesc = XFubenActivityBossSingleConfigs.GetStageAttention(self.StageId)
    local attentionDescTitle = XFubenActivityBossSingleConfigs.GetStageAttentionTitle(self.StageId)
    local title = CsXTextManager.GetText("ActivityBossSingleAttention")
    XLuaUiManager.Open("UiAttentionDesc", title, attentionDesc, attentionDescTitle)
end

--作战准备按钮点击
function XUiActivityBossSinglePopupStageDetail:OnBtnEnterClick()
    XDataCenter.FubenActivityBossSingleManager.JumpToRoleRoom(self.StageId)
end

return XUiActivityBossSinglePopupStageDetail