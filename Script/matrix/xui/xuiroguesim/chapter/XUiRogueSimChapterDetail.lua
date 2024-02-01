---@class XUiRogueSimChapterDetail : XLuaUi
---@field private _Control XRogueSimControl
local XUiRogueSimChapterDetail = XLuaUiManager.Register(XLuaUi, "UiRogueSimChapterDetail")

function XUiRogueSimChapterDetail:OnAwake()
    self:RegisterUiEvents()
    self.Grid256.gameObject:SetActiveEx(false)
    ---@type XUiGridCommon[]
    self.GridPassRewardList = {}
end

function XUiRogueSimChapterDetail:OnStart(stageId, callBack)
    self.CallBack = callBack
    self.StageId = stageId
end

function XUiRogueSimChapterDetail:OnEnable()
    self:RefreshView()
    self:RefreshRound()
    self:RefreshProp()
    self:RefreshFinishReward()
    self:RefreshStarReward()
end

function XUiRogueSimChapterDetail:RefreshView()
    -- 名称
    local nameIconPath = self._Control:GetRogueSimStageNameIcon(self.StageId)
    self.RImgStageName:SetRawImage(nameIconPath)
    -- 描述
    self.TxtDetail.text = self._Control:GetRogueSimStageDesc(self.StageId)
end

-- 刷新回合上限
function XUiRogueSimChapterDetail:RefreshRound()
    local turnCount = self._Control:GetRogueSimStageMaxTurnCount(self.StageId)
    local desc = self._Control:GetClientConfig("StageRoundDesc", 1)
    self.TxtTarget.text = string.format(desc, turnCount)
end

-- 刷新关卡信物
function XUiRogueSimChapterDetail:RefreshProp()
    local tokenId = self._Control:GetRogueSimStageTokenId(self.StageId)
    if not XTool.IsNumberValid(tokenId) then
        self.PanelProp.gameObject:SetActiveEx(false)
        return
    end
    -- 图片
    self.RImgIcon:SetRawImage(self._Control:GetTokenIcon(tokenId))
    -- 名称
    self.TxtName.text = self._Control:GetTokenName(tokenId)
    -- 描述
    self.TxtDesc.text = self._Control:GetTokenEffectDesc(tokenId)
end

-- 刷新首通奖励
function XUiRogueSimChapterDetail:RefreshFinishReward()
    local rewardId = self._Control:GetRogueSimStageFirstFinishReward(self.StageId)
    local haveReward = XTool.IsNumberValid(rewardId)
    self.FinishReward.gameObject:SetActiveEx(haveReward)
    if not haveReward then
        return
    end

    local isPass = self._Control:CheckStageIsPass(self.StageId)
    self.FinishReward:GetObject("TxtTitleYes").gameObject:SetActiveEx(isPass)
    self.FinishReward:GetObject("TxtTitleNo").gameObject:SetActiveEx(not isPass)

    local rewards = XRewardManager.GetRewardList(rewardId)
    if not self.FinishRewardGrid then
        local go = self.FinishReward:GetObject("GridReward")
        self.FinishRewardGrid = XUiGridCommon.New(self, go)
    end
    self.FinishRewardGrid:Refresh(rewards[1])
    self.FinishRewardGrid:SetReceived(isPass)
end

-- 刷新三星奖励
function XUiRogueSimChapterDetail:RefreshStarReward()
    self.StarReward1.gameObject:SetActiveEx(false)
    self.StarReward2.gameObject:SetActiveEx(false)
    self.StarReward3.gameObject:SetActiveEx(false)

    -- 关卡记录三星达成情况
    local starMask = self._Control:GetStageRecordStarMask(self.StageId)
    local _, map = self._Control:GetStageStarCount(starMask)

    local conditions = self._Control:GetRogueSimStageStarConditions(self.StageId)
    local rewardIds = self._Control:GetRogueSimStageStarRewardIds(self.StageId)
    local descs = self._Control:GetRogueSimStageStarDescs(self.StageId)
    for i, _ in ipairs(conditions) do
        local uiObj = self["StarReward" .. i]
        local rewards = XRewardManager.GetRewardList(rewardIds[i])
        local desc = descs[i]
        local isPass = map[i]

        uiObj.gameObject:SetActiveEx(true)
        local txtTitleYes = uiObj:GetObject("TxtTitleYes")
        local txtTitleNo = uiObj:GetObject("TxtTitleNo")
        txtTitleYes.text = desc
        txtTitleNo.text = desc
        txtTitleYes.gameObject:SetActiveEx(isPass)
        txtTitleNo.gameObject:SetActiveEx(not isPass)

        local rewardGrid = self["StarRewardGrid" .. i]
        if not rewardGrid then
            local go = uiObj:GetObject("GridReward")
            rewardGrid = XUiGridCommon.New(self, go)
            self["StarRewardGrid" .. i] = rewardGrid
        end
        rewardGrid:Refresh(rewards[1])
        rewardGrid:SetReceived(isPass)
    end
end

function XUiRogueSimChapterDetail:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBg, self.OnBtnCloseClick)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
    XUiHelper.RegisterClickEvent(self, self.BtnEnter, self.OnBtnEnterClick)
end

function XUiRogueSimChapterDetail:OnBtnCloseClick()
    if self.CallBack then
        self.CallBack()
    end
    self:Close()
end

function XUiRogueSimChapterDetail:OnBtnEnterClick()
    self._Control:EnterSceneFromStage(self.StageId)
end

return XUiRogueSimChapterDetail
