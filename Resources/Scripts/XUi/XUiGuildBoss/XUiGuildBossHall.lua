--工会boss战入口窗口
local XUiGuildBossLog = require("XUi/XUiGuildBoss/Component/XUiGuildBossLog")
local XUiGuildBossPlayerRankItem = require("XUi/XUiGuildBoss/Component/XUiGuildBossPlayerRankItem")
local XUiGuildBossGuildRankItem = require("XUi/XUiGuildBoss/Component/XUiGuildBossGuildRankItem")
local XUiGuildBossHall = XLuaUiManager.Register(XLuaUi, "UiGuildBossHall")

local GuildRankType = {
    Player = 1, --个人排行
    Guild = 2,  --工会排行
}

function XUiGuildBossHall:OnAwake()
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self:BindHelpBtn(self.BtnHelp, "GuildBossHelp")
    self.BtnStart.CallBack = function() self:OnBtnStartClick() end
    self.BtnCloseFullRecord.CallBack = function() self:OnBtnCloseFullRecordClick() end
    self.BtnOpenRecord.CallBack = function() self:OnBtnOpenRecordClick() end
    self.BtnChange.CallBack = function() self:OnBtnChangeClick() end
    self.BtnRankReward.CallBack = function() self:OnBtnRankRewardClick() end

    self.LogDynamicTable = XDynamicTableIrregular.New(self.PanelRecordView)
    self.LogDynamicTable:SetProxy("XUiGuildBossLog",XUiGuildBossLog, self.RecordItem.gameObject)
    self.LogDynamicTable:SetDelegate(self)

    self.ImgEmptyPlayerRank.gameObject:SetActiveEx(false)
    self.ImgEmptyGuildRank.gameObject:SetActiveEx(false)
    self.GUildDynamicTable = XDynamicTableNormal.New(self.PanelGuildRankList)
    self.GUildDynamicTable:SetProxy(XUiGuildBossGuildRankItem)
    self.GUildDynamicTable:SetDelegate(self)
    self.GUildDynamicTable:SetDynamicEventDelegate(function(event, index, grid)
        self:OnGUildDynamicTableEvent(event, index, grid)
    end)
    self.GuildRankItem.gameObject:SetActiveEx(false)
    self.MyGuildRankObj.gameObject:SetActiveEx(false)

    self.PlayerDynamicTable = XDynamicTableNormal.New(self.PanelRankList)
    self.PlayerDynamicTable:SetProxy(XUiGuildBossPlayerRankItem)
    self.PlayerDynamicTable:SetDelegate(self)
    self.PlayerDynamicTable:SetDynamicEventDelegate(function(event, index, grid)
        self:OnPlayerDynamicTableEvent(event, index, grid)
    end)
    self.RankItem.gameObject:SetActiveEx(false)
    self.MyRankObj.gameObject:SetActiveEx(false)
    self.GuildBossChangeGuildRankStr = CS.XTextManager.GetText("GuildBossChangeGuildRankStr")
    self.GuildBossChangePlayerRankStr = CS.XTextManager.GetText("GuildBossChangePlayerRankStr")
    
    self.RankType = GuildRankType.Player
    self.BtnChange:SetName(self.GuildBossChangeGuildRankStr)

    self.PlayerRankList = {}
    self.GuildRankList = {}
    self.MyRank = nil
    self.PlayerRankNum = 5
    self.GuildRankNum = 9
    self.IsFirstTimeOpen = true
end

function XUiGuildBossHall:GetProxyType()
    return "XUiGuildBossLog"
end

function XUiGuildBossHall:OnStart()
    --首次进入展示帮助
    if not XSaveTool.GetData("ShowGuildBossHallHelp" .. XPlayer.Id) then
        XSaveTool.SaveData("ShowGuildBossHallHelp" .. XPlayer.Id, true)
        XUiManager.ShowHelpTip("GuildBossHelp")
    end
end

function XUiGuildBossHall:OnEnable()
    if self.IsFirstTimeOpen then
        self:UpdateInfo()
        self.IsFirstTimeOpen = false
    else
        XDataCenter.GuildBossManager.GuildBossInfoRequest(function() self:UpdateInfo() end)
    end
    self.BtnStart:ShowReddot(XDataCenter.GuildBossManager.IsReward())
end

--整体更新窗口数据入口
function XUiGuildBossHall:UpdateInfo()
    self.TxtLeftTime.text = XUiHelper.GetTime(XDataCenter.GuildBossManager.GetEndTime() - XTime.GetServerNowTimestamp(), XUiHelper.TimeFormatType.MAINBATTERY)
    self.TxtTotalGuildScore.text = XUiHelper.GetLargeIntNumText(XDataCenter.GuildBossManager.GetTotalScore())
    self.TxtGuildRank.text = XDataCenter.GuildBossManager.MyGuildRank
    self.RImgGuildHead:SetRawImage(XDataCenter.GuildManager.GetGuildIconId())
    self.GuildRankItemObj.gameObject:SetActiveEx(false)

    self:UpdateBossHp(0)
    self.LogData = XDataCenter.GuildBossManager.GetLogs()
    self:UpdateLogs()
    self:UpdateRank()
end

function XUiGuildBossHall:UpdateBossHp(damage)
    --更新中间boss相关信息
    local bossMaxHp = XDataCenter.GuildBossManager.GetMaxBossHp()
    local bossCurHp = XDataCenter.GuildBossManager.GetCurBossHp() - damage
    local leftHpNum = math.floor(bossCurHp / (bossMaxHp / 100)) --剩余血量管数
    self.ImgBossHp.fillAmount = (bossCurHp - (leftHpNum * (bossMaxHp / 100))) / (bossMaxHp / 100)
    self.TxtBossCurHp.text = XUiHelper.GetLargeIntNumText(bossCurHp)
    self.PanelBossBack.gameObject:SetActiveEx(bossCurHp > 0)
    self.PanelFinsh.gameObject:SetActiveEx(bossCurHp == 0)
    self.TxtBossHpNum.text = leftHpNum
    self.TxtBossHp.text = XUiHelper.GetLargeIntNumText(bossMaxHp)
end

--更新左边作战日志
function XUiGuildBossHall:UpdateLogs()
    self:UpdateDynamicTable()
end

function XUiGuildBossHall:UpdateDynamicTable()
    self.LogDynamicTable:SetDataSource(self.LogData)
    self.LogDynamicTable:ReloadDataASync(#self.LogData)
end

--更新右边排行榜
function XUiGuildBossHall:UpdateRank()
    if self.RankType == GuildRankType.Player then
        self.PlayerRankObj.gameObject:SetActiveEx(true)
        self.GuildRankObj.gameObject:SetActiveEx(false)
        XDataCenter.GuildBossManager.GuildBossPlayerRankRequest(function() self:UpdatePlayerRank() end)
    elseif self.RankType == GuildRankType.Guild then
        self.PlayerRankObj.gameObject:SetActiveEx(false)
        self.GuildRankObj.gameObject:SetActiveEx(true)
        local isSend = XDataCenter.GuildBossManager.GuildBossGuildRankRequest(function() self:UpdateGuildRank() end)
        if isSend then    
            XDataCenter.GuildBossManager.GuildBossPlayerRankRequest(function() self:UpdatePlayerRankItem() end, true) -- 以保证本公会和排名上信息一致
        end
    end
end

--更新个人排行榜
function XUiGuildBossHall:UpdatePlayerRank()
    self.RankData = XDataCenter.GuildBossManager.GetAllRankList()
    self.PlayerDynamicTable:SetDataSource(self.RankData)
    self.PlayerDynamicTable:ReloadDataASync()
    self.ImgEmptyPlayerRank.gameObject:SetActiveEx(#self.RankData == 0)
    self:UpdatePlayerRankItem()
end

function XUiGuildBossHall:UpdatePlayerRankItem()
    --我的个人排行
    if self.MyRank == nil then
        self.MyRank = XUiGuildBossPlayerRankItem.New(self.MyRankObj)
        self.MyRank.GameObject:SetActiveEx(true)
    end
    local myRankData = XDataCenter.GuildBossManager.GetMyRankData()
    local myRankNum = XDataCenter.GuildBossManager.GetMyRankNum()
    self.MyRank:Init(myRankData, myRankNum)
end

--更新工会排行榜
function XUiGuildBossHall:UpdateGuildRank()
    self.GuildRankData = XDataCenter.GuildBossManager.GetAllGuildRankList()
    self.GUildDynamicTable:SetDataSource(self.GuildRankData)
    self.GUildDynamicTable:ReloadDataASync()
    self.ImgEmptyGuildRank.gameObject:SetActiveEx(#self.GuildRankData == 0)
    --我工会的排行
    if self.MyGuildRank == nil then
        self.MyGuildRank = XUiGuildBossGuildRankItem.New(self.MyGuildRankObj)
        self.MyGuildRank.GameObject:SetActiveEx(true)
    end
    local myGuildRankData = XDataCenter.GuildBossManager.GetMyGuildRankData()
    local myGuildRankNum = XDataCenter.GuildBossManager.GetMyGuildRankNum()
    self.MyGuildRank:Init(myGuildRankData, myGuildRankNum)
end

function XUiGuildBossHall:OnBtnBackClick()
    self:Close()
end

function XUiGuildBossHall:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiGuildBossHall:OnBtnStartClick()
    XDataCenter.GuildBossManager.GuildBossActivityRequest(function() XLuaUiManager.Open("UiGuildBossStage") end)
end

--切换排行榜
function XUiGuildBossHall:OnBtnChangeClick()
    if self.RankType == GuildRankType.Player then
        self.BtnChange:SetName(self.GuildBossChangePlayerRankStr)
        self.RankType = GuildRankType.Guild
    elseif self.RankType == GuildRankType.Guild then
        self.BtnChange:SetName(self.GuildBossChangeGuildRankStr)
        self.RankType = GuildRankType.Player
    end
    self:UpdateRank()
end

--展开详细记录
function XUiGuildBossHall:OnBtnOpenRecordClick()
    self.BtnOpenRecord.gameObject:SetActiveEx(false)
    self.BtnCloseFullRecord.gameObject:SetActiveEx(true)
    self.ImgUnfoldBack.gameObject:SetActiveEx(true)
    self.PanelRecordViewRect.sizeDelta = CS.UnityEngine.Vector2(364, 780)
    self:UpdateLogs()
end

--关闭详细记录
function XUiGuildBossHall:OnBtnCloseFullRecordClick()
    self.BtnOpenRecord.gameObject:SetActiveEx(true)
    self.BtnCloseFullRecord.gameObject:SetActiveEx(false)
    self.ImgUnfoldBack.gameObject:SetActiveEx(false)
    self.PanelRecordViewRect.sizeDelta = CS.UnityEngine.Vector2(364, 526)
    self:UpdateLogs()
end

function XUiGuildBossHall:OnBtnRankRewardClick()
    XLuaUiManager.Open("UiGuildBossRankReward")
end

--工会日志动态列表事件
function XUiGuildBossHall:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Init(self.LogData[index])
    end
end

--工会排行榜动态列表事件
function XUiGuildBossHall:OnGUildDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Init(self.GuildRankData[index], index)
    end
end

--工会内部排行榜动态列表事件
function XUiGuildBossHall:OnPlayerDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Init(self.RankData[index], index)
    end
end