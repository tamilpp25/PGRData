local XUiCerberusGameTipsV2P9 = XLuaUiManager.Register(XLuaUi, "UiCerberusGameTipsV2P9")

function XUiCerberusGameTipsV2P9:OnAwake()
    self:InitButton()
    self.GridReward = {}
end

function XUiCerberusGameTipsV2P9:InitButton()
    self:RegisterClickEvent(self.BtnTanchuangCloseBig, self.Close)
    self:RegisterClickEvent(self.BtnEnter, self.OnBtnEnterClick)
end

function XUiCerberusGameTipsV2P9:OnStart(stageId, chapterId)
    self.StageId = stageId
    self.ChapterId = chapterId
end

function XUiCerberusGameTipsV2P9:OnEnable()
    self:RefreshUiShow()
end

function XUiCerberusGameTipsV2P9:RefreshUiShow()
    local xStage = XMVCA.XCerberusGame:GetXStageById(self.StageId)
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)

    -- 关卡信息
    self.StageName.text = stageCfg.Name
    self.StageDesc.text = stageCfg.Description
    self.StageIcon:SetRawImage(stageCfg.StoryIcon)

    -- 首通奖励
    local rewards = {}
    local rewardId = stageCfg.FirstRewardShow
    if rewardId > 0 then
        rewards = XRewardManager.GetRewardList(rewardId) or XRewardManager.GetRewardListNotCount(rewardId)
    end

    if rewards then
        for i, item in pairs(rewards) do
            local grid = self.GridReward[i] 
            if not grid then
                local ui = CS.UnityEngine.Object.Instantiate(self.Grid256New, self.Grid256New.parent)
                grid = XUiGridCommon.New(self, ui)
                self.GridReward[i] = grid
            end
            grid:Refresh(item)
            grid:SetReceived(xStage:GetIsPassed())
            grid.GameObject:SetActive(true)
        end
    end
    self.Grid256New.gameObject:SetActive(false)
end

function XUiCerberusGameTipsV2P9:OnBtnEnterClick()
    local canSeleRole = XMVCA.XCerberusGame:GetCanSelectRoleListForChallengeMode(self.StageId)
    local xTeam = XMVCA.XCerberusGame:GetXTeamByChapterId(self.ChapterId)
    -- 检查队伍
    XMVCA.XCerberusGame:ReInitXTeamV2P9(canSeleRole, self.ChapterId)

    XLuaUiManager.PopThenOpen("UiBattleRoleRoom", self.StageId
            , xTeam
            , require("XUi/XUiCerberusGame/Proxy/XUiCerberusGameBattleRoomProxy"))
end

return XUiCerberusGameTipsV2P9