-- 调色战争结算界面
local XUiColorTableSettleWin = XLuaUiManager.Register(XLuaUi, "UiColorTableSettleWin")

local MaxBossCnt = 4
local BossPos = 0 -- boss的位置

function XUiColorTableSettleWin:OnAwake()
    self.Data = nil -- 战斗数据
    self.CurStageId = 0 -- 当前副本玩法的关卡id，区别战斗关卡id
    self.GridCommonDic = {}

    self:SetButtonCallBack()
end

function XUiColorTableSettleWin:OnStart(data, curStageId, captainId, isFirstPass)
    self.Data = data
    self.CurStageId = curStageId
    self.CaptainId = captainId
    self.IsFirstPass = isFirstPass or false
    self.WinType = XDataCenter.ColorTableManager.GetWinType(data.WinConditionId, curStageId)
end

function XUiColorTableSettleWin:OnEnable()
    self:Refresh()
end

function XUiColorTableSettleWin:OnDisable()

end

function XUiColorTableSettleWin:SetButtonCallBack()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
end

function XUiColorTableSettleWin:OnBtnCloseClick()
    local isMapLose = XTool.IsNumberValid(XDataCenter.ColorTableManager.GetGameManager():GetGameData():GetIsLose())
    local isOpenUiChoice = self.WinType ~= XColorTableConfigs.WinType.Break or isMapLose
    if isOpenUiChoice then
        local characterId = XColorTableConfigs.GetStageChapterId(self.CurStageId)
        local difficultyId = XColorTableConfigs.GetStageDifficultyId(self.CurStageId)
        XLuaUiManager.OpenWithCallback("UiColorTableChoicePlay", function()
            XLuaUiManager.Remove("UiColorTableSettleWin")
        end, characterId, difficultyId)
    else
        self:Close()
    end
end

function XUiColorTableSettleWin:Refresh()
    self.TxtTitle.text = XColorTableConfigs.GetStageName(self.CurStageId)

    self:RefreshDataList()
    self:RefreshCaptain()
    self:RefreshKillBossList()
    self:RefreshRewardList()
end

function XUiColorTableSettleWin:RefreshDataList()
    self.TxtCondDesc1.text = self.Data.RoundCount
    self.TxtCondDesc2.text = self.Data.BossTotalLevel
    self.TxtCondDesc3.text = self.Data.StudyCount .. XUiHelper.GetText("TowerTimes")
end

function XUiColorTableSettleWin:RefreshCaptain()
    local icon = XColorTableConfigs.GetCaptainSettleIcon(self.CaptainId)
    self.RImgRole:SetRawImage(icon)

    local stageCfg = XColorTableConfigs.GetColorTableStage(self.CurStageId)
    local startKeyList = {"Break", "NormalWin", "SpecialWin"}
    local startKey = startKeyList[self.WinType]
    self.TxtRoleTittle.text = stageCfg[startKey.."Title"]
    self.TxtRoleDesc.text = stageCfg[startKey.."Desc"]

    self.TxtNew.gameObject:SetActiveEx(self.IsFirstPass)
end

function XUiColorTableSettleWin:RefreshKillBossList()
    local mapId = XColorTableConfigs.GetStageMapId(self.CurStageId)
    local pointGroupId = XColorTableConfigs.GetMapPointGroupId(mapId)

    -- 只有中断结算才会发杀死的boss，正常关胜利和特殊条件胜利都要填充boss
    local colorList = self.Data.KillBoss
    if self.WinType == XColorTableConfigs.WinType.NormalWin then
        table.insert(colorList, XColorTableConfigs.ColorType.Red)
        table.insert(colorList, XColorTableConfigs.ColorType.Green)
        table.insert(colorList, XColorTableConfigs.ColorType.Blue)
    elseif self.WinType == XColorTableConfigs.WinType.SpecialWin then
        table.insert(colorList, XColorTableConfigs.HideBossColor)
    end

    -- 刷新boss列表
    for colorId = 0, MaxBossCnt-1 do
        local config =  XColorTableConfigs.GetPointConfig(pointGroupId, BossPos, colorId)
        local isShow = table.contains(colorList, colorId) and config ~= nil
        self["GridBoss"..colorId].gameObject:SetActiveEx(isShow)
        if isShow then
            self["RImgIconBoss"..colorId]:SetRawImage(config.Icon)
        end
    end
end

function XUiColorTableSettleWin:RefreshRewardList()
    self.GridReward.gameObject:SetActiveEx(false)
    local index = 1
    if self.Data.FirstRewardList then
        for _, reward in ipairs(self.Data.FirstRewardList) do
            self:RefreshOneReward(index, reward, true)
            index = index + 1
        end
    end
    
    if self.Data.RewardList then
        for _, reward in ipairs(self.Data.RewardList) do
            self:RefreshOneReward(index, reward, false)
            index = index + 1
        end
    end
end

function XUiColorTableSettleWin:RefreshOneReward(index, reward, isFirst)
    local grid = self.GridCommonDic[index]
    if grid == nil then
        local go = nil
        if self.PanelRewardContent.childCount >= index then
            go = self.PanelRewardContent:GetChild(index - 1)
        else
            go = CS.UnityEngine.Object.Instantiate(self.GridReward, self.PanelRewardContent)
        end
        go.gameObject:SetActiveEx(true)
        local imgFirst = XUiHelper.TryGetComponent(go, "ImgFirst")
        imgFirst.gameObject:SetActiveEx(isFirst)

        grid = XUiGridCommon.New(go)
        self.GridCommonDic[index] = grid
    end
    grid:Refresh(reward)
end