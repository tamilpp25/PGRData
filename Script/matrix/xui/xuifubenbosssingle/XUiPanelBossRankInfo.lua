local XUiTabBtnGroup = require("XUi/XUiBase/XUiTabBtnGroup")
---@class XUiPanelBossRankInfo : XUiNode
---@field Parent XUiFubenBossSingle
---@field _Control XFubenBossSingleControl
local XUiPanelBossRankInfo = XClass(XUiNode, "XUiPanelBossRankInfo")
local XUiPanelMyBossRank = require("XUi/XUiFubenBossSingle/XUiPanelMyBossRank")
local XUiGridBossRank = require("XUi/XUiFubenBossSingle/XUiGridBossRank")

function XUiPanelBossRankInfo:OnStart()
    ---@type XBossSingle
    local bossSingleData = self.Parent:GetBossSingleData()

    ---@type XUiGridBossRank[]
    self._GridRankList = {}
    self._CurLevelType = bossSingleData:GetBossSingleLevelType()
    self._RankPlatform = bossSingleData:GetBossSingleRankPlatform()
    self._Timer = nil
    self.GridRankLevel.gameObject:SetActive(false)
    self.GridBossRank.gameObject:SetActive(false)
    self.TxtCurTime.text = ""
    self:_RegisterButtonListeners()
    self:_Init()
end

function XUiPanelBossRankInfo:OnEnable()
    self:_Refresh()
    self:_RefreshTime()
end 

function XUiPanelBossRankInfo:OnDisable()
    self:_RemoveTimer()
end

function XUiPanelBossRankInfo:_RegisterButtonListeners()
    XUiHelper.RegisterClickEvent(self, self.BtnRankReward, self.OnBtnRankRewardClick, true)
end

function XUiPanelBossRankInfo:_Init()
    if self.TabBtnGroup then
        self.TabBtnGroup:Dispose()
    end
    self.TabBtnGroup = nil
    self.BtnTabList = {}
    self.BtnIndexDic = {}
    
    local Cfgs = self._Control:GetBossGradeConfigs()
    for i = 1, #Cfgs do
        if self._Control:GetRankIsOpenByType(Cfgs[i].LevelType) then
            local grid = CS.UnityEngine.Object.Instantiate(self.GridRankLevel)
            grid.transform:SetParent(self.PanelTags, false)
            grid.gameObject:SetActive(true)
            table.insert(self.BtnTabList, grid)
            self.BtnIndexDic[#self.BtnIndexDic + 1] = Cfgs[i].LevelType
        end
    end

    self.TabBtnGroup = XUiTabBtnGroup.New(self.BtnTabList, function(levelType)
        self:_RefreshRankInfo(levelType)
    end)

    for k, btn in ipairs(self.TabBtnGroup.TabBtnList) do
        local type = self.BtnIndexDic[k]
        local text = XUiHelper.GetText("BossSingleRankDesc", Cfgs[type].MinPlayerLevel, Cfgs[type].MaxPlayerLevel)
        btn:SetName(Cfgs[type].LevelName, text)
        local icon = btn.Transform:Find("RImgIcon"):GetComponent("RawImage")
        icon:SetRawImage(Cfgs[type].Icon)
        self.TabBtnGroup:UnLockIndex(k)
    end

    ---@type XUiPanelMyBossRank
    self.MyBossRank = XUiPanelMyBossRank.New(self.PanelMyBossRank, self, self.Parent)
    self.MyBossRank:Close()
end

function XUiPanelBossRankInfo:_Refresh()
    local index = 1
    ---@type XBossSingle
    local bossSingleData = self.Parent:GetBossSingleData()

    self._CurLevelType = bossSingleData:GetBossSingleLevelType()
    self._RankPlatform = bossSingleData:GetBossSingleRankPlatform()

    for i = 1, #self.BtnIndexDic do
        if self.BtnIndexDic[i] == self._CurLevelType then
            index = i
        end
    end

    self.TabBtnGroup:SelectIndex(index)
    self.Parent:PlayAnimation("AnimRankInfolEnable")
end

function XUiPanelBossRankInfo:_RefreshRankInfo(levelType)
    local indexType = self.BtnIndexDic[levelType] or 1

    self._CurLevelType = indexType
    self.Parent:PlayAnimation("AnimInfoQieHuan")
    self:_RefreshRank()
end

function XUiPanelBossRankInfo:_RemoveTimer()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = nil
    end
end

function XUiPanelBossRankInfo:_RefreshRank()
    XMVCA.XFubenBossSingle:RequestRankData(function(rankData)
        self:_SetRankInfo(rankData)
        self:_RefreshMyRankInfo(rankData)
    end, self._CurLevelType)
end

function XUiPanelBossRankInfo:_RefreshTime()
    XMVCA.XFubenBossSingle:RequestRankData(function(rankData)
        self:_SetLeftTime(rankData)
    end, self._CurLevelType)
end

---@param rankData XBossSingleRankData
function XUiPanelBossRankInfo:_SetLeftTime(rankData)
    local leftTime = rankData:GetLeftTime()
    if self._Timer then
        self:_RemoveTimer()
    end

    self._Timer = XScheduleManager.ScheduleForever(function()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end

        local desc = "BossSingleLeftTimeIos"
        if self._RankPlatform == XEnumConst.BossSingle.Platform.Win then
            desc = "BossSingleLeftTimeWin"
        elseif self._RankPlatform == XEnumConst.BossSingle.Platform.Android then
            desc = "BossSingleLeftTimeAndroid"
        elseif self._RankPlatform == XEnumConst.BossSingle.Platform.IOS then
            desc = "BossSingleLeftTimeIos"
        elseif self._RankPlatform == XEnumConst.BossSingle.Platform.All then
            desc = "BossSingleLeftTimeAll"
        end
        self.TxtIos.text =  XUiHelper.GetText(desc)

        leftTime = leftTime - 1
        if leftTime <= 0 then
            local dataTime = XUiHelper.GetTime(0)
            self.TxtCurTime.text = XUiHelper.GetText("BossSingleLeftTime", dataTime)
            self:_RemoveTimer()
        else
            local dataTime = XUiHelper.GetTime(leftTime)
            self.TxtCurTime.text = XUiHelper.GetText("BossSingleLeftTime", dataTime)
        end
    end, 1000)
end

---@param rankData XBossSingleRankData
function XUiPanelBossRankInfo:_SetRankInfo(rankData)
    local count = rankData:GetRankListCount()
    local maxCount =  self._Control:GetMaxRankCount()

    if count > maxCount then
        count = maxCount
    end

    for i = 1, count do
        local grid = self._GridRankList[i]
        if not grid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridBossRank)
            grid = XUiGridBossRank.New(ui, self, self.Parent)
            grid.Transform:SetParent(self.PanelRankContent, false)
            self._GridRankList[i] = grid
        end

        grid:SetData(rankData:GetRankByIndex(i), self._CurLevelType)
        grid:Open()
    end

    for i = count + 1, #self._GridRankList do
        self._GridRankList[i]:Close()
    end

    self.PanelNoRank.gameObject:SetActiveEx(count <= 0)
end

---@param rankData XBossSingleRankData
function XUiPanelBossRankInfo:_RefreshMyRankInfo(rankData)
    local myLevelType = self._Control:GetBossSingleData():GetBossSingleLevelType()

    self.MyRankData = {
        MylevelType = myLevelType,
        MineRankNum = rankData:GetRankNumber(),
        HistoryMaxRankNum = rankData:GetHistoryNumber(),
        TotalCount = rankData:GetTotalCount(),
    }

    if self._CurLevelType == myLevelType then
        self.MyBossRank:SetData(self.MyRankData)
        self.MyBossRank:Open()
    else
        self.MyBossRank:Close()
    end
end

function XUiPanelBossRankInfo:OnBtnRankRewardClick()
    self.Parent:ShowRankRewardPanel(self._CurLevelType, self.MyRankData)
end

return XUiPanelBossRankInfo