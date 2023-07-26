local ipairs = ipairs
local XUiGridTeamInfoExp = require("XUi/XUiAssign/XUiGridTeamInfoExp")
local XUiAssignPostWarCount = XLuaUiManager.Register(XLuaUi, "UiAssignPostWarCount")
local ANIMATION_OPEN = "AniBfrtPostWarCountBegin"

function XUiAssignPostWarCount:OnAwake()
    self:InitComponent()
end

-- forceOnlyIndex:强制只显示这个梯队的数据
function XUiAssignPostWarCount:OnStart(data, forceOnlyIndex)
    self.ForceOnlyIndex = forceOnlyIndex 
    self:ResetDataInfo()
    self:UpdateDataInfo(data)
    self:PlayAnimation(ANIMATION_OPEN)
end

function XUiAssignPostWarCount:InitComponent()
    self:RegisterClickEvent(self.BtnExit, self.OnBtnExitClick)
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)

    self.GridEchelonExp.gameObject:SetActive(false)
    self.GridReward.gameObject:SetActive(false)
    self.GridEchelonExp.gameObject:SetActive(false)
end

function XUiAssignPostWarCount:OnNotify(evt, ...)
    local args = { ... }
    if evt == CS.XEventId.EVENT_UI_ALLOWOPERATE and args[1] == self.Ui then
        XDataCenter.FunctionEventManager.UnLockFunctionEvent()
    end
end

function XUiAssignPostWarCount:OnGetEvents()
    return { CS.XEventId.EVENT_UI_ALLOWOPERATE }
end

function XUiAssignPostWarCount:ResetDataInfo()
    self.RewardGoodsList = {}
    self.GroupId = nil
end

function XUiAssignPostWarCount:UpdateDataInfo(data)
    self.RewardGoodsList = data.RewardGoodsList
    self.GroupId = XDataCenter.FubenAssignManager.GetGroupIdByStageId(data.StageId)

    self:UpdatePanelRewardContent()
    self:UpdatePanelEchelonExpContent()
    self:UpdatePanelPlayer()
end


function XUiAssignPostWarCount:OnBtnExitClick()
    self:Close()
end

function XUiAssignPostWarCount:OnBtnCloseClick()
    self:Close()
end

function XUiAssignPostWarCount:UpdatePanelRewardContent()
    local rewards = XRewardManager.MergeAndSortRewardGoodsList(self.RewardGoodsList)
    for _, item in ipairs(rewards) do
        local ui = CS.UnityEngine.Object.Instantiate(self.GridReward)
        local grid = XUiGridCommon.New(self, ui)
        grid.Transform:SetParent(self.PanelRewardContent, false)
        grid:Refresh(item, nil, nil, true)
        grid.GameObject:SetActive(true)
    end
end

function XUiAssignPostWarCount:UpdatePanelEchelonExpContent()
    local groupData = XDataCenter.FubenAssignManager.GetGroupDataById(self.GroupId)
    local baseStageId = groupData:GetBaseStageId()

    for index, teamInfoId in ipairs(groupData:GetTeamInfoId()) do
        local doFun = function ()
            local ui = CS.UnityEngine.Object.Instantiate(self.GridEchelonExp)
            local grid = XUiGridTeamInfoExp.New(self, ui, baseStageId, index, teamInfoId)
            grid.Transform:SetParent(self.PanelEchelonExpContent, false)
            grid.GameObject:SetActive(true)
        end

        if self.ForceOnlyIndex then
            if self.ForceOnlyIndex == index then
                doFun()
            end
        else
            doFun()
        end 
    end
end

function XUiAssignPostWarCount:UpdatePanelPlayer()
    local groupData = XDataCenter.FubenAssignManager.GetGroupDataById(self.GroupId)
    local curLevel = XPlayer.GetLevelOrHonorLevel()
    local curExp = XPlayer.Exp
    local maxExp = XPlayer.GetMaxExp()
    local teamExp = XDataCenter.FubenManager.GetTeamExp(groupData:GetBaseStageId())

    self.TxtLevel.text = curLevel
    if XPlayer.IsHonorLevelOpen() then
        self.TxtLevelName.text = CS.XTextManager.GetText("HonorLevel")
    end
    self.TxtAddExp.text = "+ " .. teamExp
    self.ImgExp.fillAmount = curExp / maxExp
end