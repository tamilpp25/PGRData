local XUiGridTemplateSelectRoom = require("XUi/XUiDormTemplate/XUiGridTemplateSelectRoom")
local XUiPanelTemlateSelectRoom = XClass(nil, "XUiPanelTemlateSelectRoom")

function XUiPanelTemlateSelectRoom:Ctor(ui, rootUi, sureCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.SureCb = sureCb
    self.GridRoomList = {}

    XTool.InitUiObject(self)
    self:AddListener()
    self:Init()
end

function XUiPanelTemlateSelectRoom:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiPanelTemlateSelectRoom:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiPanelTemlateSelectRoom:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiPanelTemlateSelectRoom:AddListener()
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnAllClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnCancel, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnSure, self.OnBtnSureClick)
end

function XUiPanelTemlateSelectRoom:Init()
    self.GridTemplateSelectRoom.gameObject:SetActiveEx(false)
    self.GameObject:SetActiveEx(false)
end

function XUiPanelTemlateSelectRoom:OnBtnCloseClick()
    self:Close()
end

function XUiPanelTemlateSelectRoom:OnBtnSureClick()
    -- 重复绑定同一个宿舍
    if self.ConnectId > 0 and self.ConnectId == self.SelectId then
        XUiManager.TipMsg(CS.XTextManager.GetText("DormTemplateSelectTip"))
        return
    end

    -- 没有选择宿舍
    if self.ConnectId <= 0 and self.SelectId <= 0 then
        XUiManager.TipMsg(CS.XTextManager.GetText("DormTemplateSelectNoneTip"))
        return
    end

    -- 取消绑定当前宿舍
    if self.ConnectId > 0 and self.SelectId <= 0 then
        local titletext = CS.XTextManager.GetText("TipTitle")
        local contenttext = CS.XTextManager.GetText("DormTemplateSelectCancelTip")

        
        local cancelConectFunc = function()
            local conectRoom = XDataCenter.DormManager.GetRoomDataByRoomId(self.ConnectId)
            self.HomeRoomData:SetConnectDormId(0)
            conectRoom:SetConnectDormId(0)
            local isUnBind = true
            self:CallBackHandle(isUnBind)
        end

        XUiManager.DialogTip(titletext, contenttext, XUiManager.DialogType.Normal, nil, function()
            XDataCenter.DormManager.DormUnBindLayoutReq(self.ConnectId, cancelConectFunc)
        end)

        return
    end

    local selectRoom = XDataCenter.DormManager.GetRoomDataByRoomId(self.SelectId)

    -- 正常绑定宿舍
    if self.ConnectId <= 0 and self.SelectId > 0 and selectRoom:GetConnectDormId() <= 0 then
        XDataCenter.DormManager.DormBindLayoutReq(self.SelectId, self.HomeRoomData:GetRoomId(), function()
            self.HomeRoomData:SetConnectDormId(self.SelectId)
            selectRoom:SetConnectDormId(self.HomeRoomData:GetRoomId())
            self:CallBackHandle()
        end)
        return
    end

    -- 当前没有绑定宿舍 并且绑定了一个有绑定关系的宿舍
    if self.ConnectId <= 0 and self.SelectId > 0 and selectRoom:GetConnectDormId() > 0 then
        local titletext = CS.XTextManager.GetText("TipTitle")
        local contenttext = CS.XTextManager.GetText("DormTemplateSelectHaveTip1", selectRoom:GetRoomName())

        local conectFunc = function()
            local unbingRoom = XDataCenter.DormManager.GetRoomDataByRoomId(selectRoom:GetConnectDormId(), XDormConfig.DormDataType.Template)
            unbingRoom:SetConnectDormId(0)

            selectRoom:SetConnectDormId(self.HomeRoomData:GetRoomId())
            self.HomeRoomData:SetConnectDormId(self.SelectId)
            self:CallBackHandle()
        end

        XUiManager.DialogTip(titletext, contenttext, XUiManager.DialogType.Normal, nil, function()
            XDataCenter.DormManager.DormBindLayoutReq(self.SelectId, self.HomeRoomData:GetRoomId(), conectFunc)
        end)
        return
    end

    -- 当前有绑定宿舍 并且绑定了一个没有有绑定关系的宿舍
    if self.ConnectId > 0 and self.SelectId > 0 and selectRoom:GetConnectDormId() <= 0 then
        local titletext = CS.XTextManager.GetText("TipTitle")
        local conectRoom = XDataCenter.DormManager.GetRoomDataByRoomId(self.ConnectId)
        local contenttext = CS.XTextManager.GetText("DormTemplateSelectHaveTip1", conectRoom:GetRoomName())

        local conectFunc = function()
            local conectCurRoom = XDataCenter.DormManager.GetRoomDataByRoomId(self.ConnectId)
            conectCurRoom:SetConnectDormId(0)

            selectRoom:SetConnectDormId(self.HomeRoomData:GetRoomId())
            self.HomeRoomData:SetConnectDormId(self.SelectId)
            self:CallBackHandle()
        end

        XUiManager.DialogTip(titletext, contenttext, XUiManager.DialogType.Normal, nil, function()
            XDataCenter.DormManager.DormBindLayoutReq(self.SelectId, self.HomeRoomData:GetRoomId(), conectFunc)
        end)
        return
    end

    -- 当前有绑定宿舍 并且又绑定了一个有绑定关系的宿舍
    if self.ConnectId > 0 and self.SelectId > 0 and selectRoom:GetConnectDormId() > 0 then
        local titletext = CS.XTextManager.GetText("TipTitle")
        local contenttext = CS.XTextManager.GetText("DormTemplateSelectHaveTip2", selectRoom:GetRoomName())

        local conectFunc = function()
            local conectRoom = XDataCenter.DormManager.GetRoomDataByRoomId(self.ConnectId)
            conectRoom:SetConnectDormId(0)
            local unbingRoom = XDataCenter.DormManager.GetRoomDataByRoomId(selectRoom:GetConnectDormId(), XDormConfig.DormDataType.Template)
            unbingRoom:SetConnectDormId(0)

            selectRoom:SetConnectDormId(self.HomeRoomData:GetRoomId())
            self.HomeRoomData:SetConnectDormId(self.SelectId)
            self:CallBackHandle()
        end

        XUiManager.DialogTip(titletext, contenttext, XUiManager.DialogType.Normal, nil, function()
            XDataCenter.DormManager.DormBindLayoutReq(self.SelectId, self.HomeRoomData:GetRoomId(), conectFunc)
        end)
        return
    end
end

function XUiPanelTemlateSelectRoom:CallBackHandle(isUnBind)
    local content = isUnBind and "DormTemplateUnSelectSuccess" or "DormTemplateSelectSuccess"
    XUiManager.TipSuccess(CS.XTextManager.GetText(content))

    if self.SureCb then
        self.SureCb(self.HomeRoomData)
    end

    self:Close()
end

function XUiPanelTemlateSelectRoom:Open(homeRoomData, curDormId)
    self.HomeRoomData = homeRoomData
    self.ConnectId = self.HomeRoomData:GetConnectDormId()
    self.SelectId = self.ConnectId
    self.CurDormId = curDormId

    local dormDatas = XDataCenter.DormManager.GetDormitoryData()
    local dataList = {}
    for _, v in pairs(dormDatas) do
        if v:WhetherRoomUnlock() then
            table.insert(dataList, v)
        end
    end

    table.sort(dataList, function(a, b)
        local sortA = XDormConfig.GetDormitoryCfgById(a.Id).InitNumber
        local sortB = XDormConfig.GetDormitoryCfgById(b.Id).InitNumber

        return sortA < sortB
    end)

    for _, v in ipairs(self.GridRoomList) do
        v.GameObject:SetActiveEx(false)
    end

    for i, data in ipairs(dataList) do
        local roomGrid = self.GridRoomList[i]
        if not roomGrid then
            local grid = CS.UnityEngine.GameObject.Instantiate(self.GridTemplateSelectRoom)
            grid.transform:SetParent(self.PanelDormContent, false)
            roomGrid = XUiGridTemplateSelectRoom.New(grid)
            table.insert(self.GridRoomList, roomGrid)
        end

        roomGrid:Refresh(data, self.ConnectId, function(roomId)
            -- 取消选择
            if self.SelectId == roomId then
                self.SelectId = 0
                self:SetGridSelected(self.SelectId)
                return
            end

            self.SelectId = roomId
            self:SetGridSelected(roomId)
        end, self.CurDormId)
        roomGrid.GameObject:SetActiveEx(true)
    end

    self.GameObject:SetActiveEx(true)
end

function XUiPanelTemlateSelectRoom:SetGridSelected(roomId)
    for _, v in ipairs(self.GridRoomList) do
        local id = v.RoomData:GetRoomId()
        v:SetSelected(id == roomId)
    end
end

function XUiPanelTemlateSelectRoom:Close()
    self.GameObject:SetActiveEx(false)
end

return XUiPanelTemlateSelectRoom