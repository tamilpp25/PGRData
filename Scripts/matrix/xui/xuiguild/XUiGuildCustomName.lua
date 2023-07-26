local XUiGuildCustomName = XLuaUiManager.Register(XLuaUi, "UiGuildCustomName")
local Json = require("XCommon/Json")
local XUiGridCustomNameItem = require("XUi/XUiGuild/XUiChildItem/XUiGridCustomNameItem")
local Type = {
    Main = 1,
    NameSelect = 2,
}

function XUiGuildCustomName:OnAwake()
    self.CustomName.gameObject:SetActiveEx(false)
    self.GridName.gameObject:SetActiveEx(false)
    self.BtnTanchuangClose.CallBack = function() self:OnBtnTanchuangClose() end
    self.BtnNo.CallBack = function() self:OnBtnNoClick() end
    self.BtnYse.CallBack = function() self:OnBtnYseClick() end
    self.CustomNameList = {}
end

function XUiGuildCustomName:OnStart()
    self:SwitchPanel(Type.Main)
    self:RefreshAllPosition()
    self.NameSelectIndex = 0
    self.RankSelectIndex = 0
    self.TabBtns = {}
    self.NameItems = {}
    self.GuildCustomName = XDataCenter.GuildManager.GetGuildCustomName()
end

function XUiGuildCustomName:SwitchPanel(type)
    self.Type = type
    self.PanelMain.gameObject:SetActiveEx(type == Type.Main)
    self.PanelNameSelect.gameObject:SetActiveEx(type == Type.NameSelect)
    if type == Type.Main then
        self.TxtTitle.text = CS.XTextManager.GetText("GuildCustomRankTitle")
    elseif type == Type.NameSelect then
        self.TxtTitle.text = CS.XTextManager.GetText("GuildCustomRankSelectTitle")
    end
end

function XUiGuildCustomName:RefreshAllPosition()
    local allPositions = XGuildConfig.GetAllGuildPositions()
    local level = XDataCenter.GuildManager.GetCurRankLevel()
    self.PositionConfigs = {}
    for id, positionData in pairs(allPositions) do
        table.insert(self.PositionConfigs, {
            Id = id,
            Name = positionData.Name,
            Priority = positionData.Priority,
            Authority = positionData.Authority,
            IsEdit = level <= id
        })
    end
    table.sort(self.PositionConfigs, function(positionA, positionB)
        return positionA.Priority < positionB.Priority
    end)

    for i = 1, #self.PositionConfigs do
        if not self.CustomNameList[i] then
            local ui = CS.UnityEngine.Object.Instantiate(self.CustomName)
            ui.transform:SetParent(self.PanelCustomName, false)
            self.CustomNameList[i] = XUiGridCustomNameItem.New(ui, self)
        end
        self.CustomNameList[i].GameObject:SetActiveEx(true)
        self.CustomNameList[i]:SetItemData(self.PositionConfigs[i])
    end
    for i = #self.PositionConfigs + 1, #self.CustomNameList do
        self.CustomNameList[i].GameObject:SetActiveEx(false)
    end
end

function XUiGuildCustomName:OpenNameSelectPanel(rank, oldName)
    self.RankSelectIndex = rank
    self:SwitchPanel(Type.NameSelect)
    self.NameSelectIndex = 1
    for index, name in ipairs(self.GuildCustomName[rank]) do
        if not self.TabBtns[index] then
            local tmpGrid = CS.UnityEngine.Object.Instantiate(self.GridName)
            tmpGrid.transform:SetParent(self.PanelNameGrp, false)
            tmpGrid.gameObject:SetActiveEx(true)
            local tmpObj = {Transform = tmpGrid.transform, GameObject = tmpGrid.gameObject}
            XTool.InitUiObject(tmpObj)
            tmpObj.BtnSelect.SubGroupIndex = -1
            tmpObj.BtnSelect:SetName(name) 
            table.insert(self.NameItems, tmpObj)
            table.insert(self.TabBtns, tmpObj.BtnSelect)
        else
            self.NameItems[index].GameObject:SetActiveEx(true)
            self.TabBtns[index]:SetName(name)
        end
        if name == oldName then
            self.NameSelectIndex = index
        end
    end
    for i = #self.GuildCustomName[rank] + 1, #self.TabBtns do
        self.NameItems[i].GameObject:SetActiveEx(false)
    end
    self.BtnGrpCustomName:Init(self.TabBtns, function(index) self:OnSelectedName(index) end)
    self.BtnGrpCustomName:SelectIndex(self.NameSelectIndex, true)
    return 
end

function XUiGuildCustomName:OnSelectedName(index)
    self.NameSelectIndex = index
end

function XUiGuildCustomName:OnBtnYseClick()
    if self.Type == Type.Main then
        local customNameTable = {}
        local customNameCount = {}
        local hasModify = false         --是否跟上次一样
        for i = 1, #self.PositionConfigs do
            local positionData = self.PositionConfigs[i]
            local customName = self.CustomNameList[i]:GetInputName()
            local oldName = XDataCenter.GuildManager.GetRankNameByLevel(positionData.Id)
            customName = (customName == "") and oldName or customName
            table.insert(customNameTable,{
                Id = positionData.Id,
                Name = customName
            })
            if customName ~= oldName then
                hasModify = true
            end
            if not customNameCount[customName] then
                customNameCount[customName] = 0
            end
            customNameCount[customName] = customNameCount[customName] + 1
        end
        if not hasModify then
            XUiManager.TipMsg(CS.XTextManager.GetText("GuildRankNameHasNotChanged"))
            return
        end

        for _, count in pairs(customNameCount or {}) do
            if count > 1 then
                XUiManager.TipMsg(CS.XTextManager.GetText("GuildCustomRankHasSame"))
                return
            end
        end

        local encode_custom = Json.encode(customNameTable)
        XDataCenter.GuildManager.ChangeRankName(encode_custom, function()
            self:RefreshAllPosition()
            self:Close()
        end)
    elseif self.Type == Type.NameSelect then
        if self.RankSelectIndex == 0 or self.NameSelectIndex == 0 then return end
        local rank = self.RankSelectIndex
        self.CustomNameList[rank]:SetName(self.GuildCustomName[rank][self.NameSelectIndex])
        self:SwitchPanel(Type.Main)
    end
end

function XUiGuildCustomName:OnBtnNoClick()
    if self.Type == Type.Main then
        self:OnBtnTanchuangClose()
    elseif self.Type == Type.NameSelect then
        self.NameSelectIndex = 0
        self:SwitchPanel(Type.Main)
    end
end

function XUiGuildCustomName:OnBtnTanchuangClose()
    self:Close()
end

