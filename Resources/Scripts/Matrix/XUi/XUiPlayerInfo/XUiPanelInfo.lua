XUiPanelInfo = XClass(nil, "XUiPanelInfo")
local TextManager = CS.XTextManager

function XUiPanelInfo:Ctor(ui, rootUi)
    self.RootUi = rootUi
    self.Transform = ui.transform
    self.GameObject = ui.gameObject
    XTool.InitUiObject(self)

    self.BtnDorm.CallBack = function() self:OnBtnDorm() end
    self.BtnExhibition.CallBack = function() self:OnBtnExhibition() end
    self.BtnFriendLevel.CallBack = function() self:OnBtnFriendLevel() end
    self.BtnGuild.CallBack = function() self:OnBtnGuild() end
    
    self.BtnFriendLevel.gameObject:SetActiveEx(not (self.RootUi.Data.Id == XPlayer.Id))
    self.BtnExhibition.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.CharacterExhibition))

    self:InitDynamicTable()
end

function XUiPanelInfo:Show()
    self.GameObject:SetActiveEx(true)
    self:SetupDynamicTable()
    self:UpdateInfo()
end

function XUiPanelInfo:UpdateInfo()
    local data = self.RootUi.Data
    self.MedalInfos = data.MedalInfos

    -- 成就
    self.TxtAchievement.text = data.AchievementDetail.Achievement .. "/" .. data.AchievementDetail.TotalAchievement
    if (data.Birthday == nil) then
        self.TxtBirthday.text = TextManager.GetText("Birthday", "--", "--")
    else
        self.TxtBirthday.text = TextManager.GetText("Birthday", data.Birthday.Mon, data.Birthday.Day)
    end

    -- 羁绊
    if data.Id == XPlayer.Id then
        self.TxtFriendLevel.text = "-"
    elseif XDataCenter.SocialManager.CheckIsFriend(data.Id) then
        self.TxtFriendLevel.text = XDataCenter.SocialManager.GetFriendExpLevel(data.Id)
    else
        self.TxtFriendLevel.text = TextManager.GetText("IsNotFriend")
    end

    -- 宿舍
    local playerId = self.RootUi.Data.Id
    local appearanceShowType = (self.RootUi.Data.AppearanceSettingInfo or {}) .DormitoryType
    local hasPermission = XDataCenter.DormManager.HasDormPermission(playerId, appearanceShowType)

    if hasPermission then
        if data.DormDetail then
            self.BtnDorm.gameObject:SetActiveEx(true)
            self.TxtDormName.text = data.DormDetail.DormitoryName
        else
            -- 宿舍系统未开启
            self.BtnDorm.gameObject:SetActiveEx(false)
            self.TxtDormName.text = TextManager.GetText("DormDisable")
        end
    else
        self.BtnDorm.gameObject:SetActiveEx(false)
        self.TxtDormName.text = TextManager.GetText("PlayerInfoWithoutPermission")
    end

    --收集
    local collectionRate = XDataCenter.ExhibitionManager.GetCollectionRate(true)
    self.TxtExhibition.text = math.floor(collectionRate * 100) .. "%"

    -- 指挥局
    local guildDetail = data.GuildDetail
    local guildName = guildDetail and guildDetail.GuildName
    if guildDetail == nil or not guildName or string.len(guildName) == 0 then
        self.TxtGuildName.text = TextManager.GetText("GuildNoneJoinGuild")
        self.BtnGuild.gameObject:SetActiveEx(false)
    else
        self.TxtGuildName.text = guildDetail.GuildName
    end
end

function XUiPanelInfo:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelMedalList)
    self.DynamicTable:SetProxy(XUiOtherPlayerGridMedal)
    self.GridMedal.gameObject:SetActiveEx(false)
    self.DynamicTable:SetDelegate(self)
end

function XUiPanelInfo:SetupDynamicTable(index)
    self.MedalData = XMedalConfigs.GetMeadalConfigs()
    self.DynamicTable:SetDataSource(self.MedalData)
    self.DynamicTable:ReloadDataSync(index and index or 1)
end

function XUiPanelInfo:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateGrid(self.MedalData[index], self.MedalInfos)
    end
end

function XUiPanelInfo:OnBtnFriendLevel()
    local data = self.RootUi.Data
    if not self.PanelPlayerInfoFetters then
        local obj = CS.UnityEngine.Object.Instantiate(self.PlayerInfoFetters)
        obj.transform:SetParent(self.PlayerInfoBase, false)
        self.PanelPlayerInfoFetters = XUiPlayerInfoFetters.New(obj, XDataCenter.SocialManager.CheckIsFriend(data.Id), XDataCenter.SocialManager.GetFriendExp(data.Id))
    else
        self.PanelPlayerInfoFetters:UpdateInfo(XDataCenter.SocialManager.CheckIsFriend(data.Id), XDataCenter.SocialManager.GetFriendExp(data.Id))
        self.PanelPlayerInfoFetters.GameObject:SetActiveEx(true)
    end
end

function XUiPanelInfo:OnBtnDorm()
    if XDataCenter.RoomManager.RoomData then
        XUiManager.TipError(TextManager.GetText("InTeamCantLookDorm"))
        return
    end

    local unionFightData = XDataCenter.FubenUnionKillRoomManager.GetUnionRoomData()
    if unionFightData and unionFightData.Id then
        XUiManager.TipError(TextManager.GetText("InTeamCantLookDorm"))
        return
    end

    local data = self.RootUi.Data
    if data and data.Id and data.DormDetail and data.DormDetail.DormitoryId then
        if XLuaUiManager.IsUiLoad("UiDormSecond") then
            XLuaUiManager.CloseWithCallback("UiPlayerInfo", function()
                XEventManager.DispatchEvent(XEventId.EVENT_DORM_VISTOR_SKIP, data.Id, data.DormDetail.DormitoryId)
            end)
            return
        end
        XHomeDormManager.EnterDorm(data.Id, data.DormDetail.DormitoryId, true)
    end
end

function XUiPanelInfo:OnBtnExhibition()
    if XDataCenter.RoomManager.RoomData then
        XUiManager.TipError(TextManager.GetText("InTeamCantLookExhibition"))
        return
    end
    local unionFightData = XDataCenter.FubenUnionKillRoomManager.GetUnionRoomData()
    if unionFightData and unionFightData.Id then
        XUiManager.TipError(TextManager.GetText("InTeamCantLookExhibition"))
        return
    end

    if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.CharacterExhibition) then
        XLuaUiManager.Open("UiExhibition", false)
    end
end

function XUiPanelInfo:OnBtnGuild()
    local data = self.RootUi.Data
    local guildId = data.GuildDetail.GuildId
    if guildId == 0 then return end
    XDataCenter.GuildManager.GetVistorGuildDetailsReq(guildId, function()
        XLuaUiManager.Open("UiGuildRankingList", guildId)
    end)
end

function XUiPanelInfo:Close()
    self.GameObject:SetActiveEx(false)
end