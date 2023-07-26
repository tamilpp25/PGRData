local XUiGuildViewSetHeadPortrait = XClass(nil, "XUiGuildViewSetHeadPortrait")
local XUiGuildHeadPortraitItem = require("XUi/XUiGuild/XUiChildItem/XUiGuildHeadPortraitItem")
---@param ui Ui
---@param parent 父Ui
---@param hideUnlock 隐藏未解锁头像
function XUiGuildViewSetHeadPortrait:Ctor(ui, parent, hideUnlock)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Parent = parent
    self.HideUnLock = hideUnlock
    XTool.InitUiObject(self)
    self:AddListener()
    self.CurHeadPortraitId = -1
    self.InitHeadPortraitId = 1
    self:InitDynamicTable()
end

function XUiGuildViewSetHeadPortrait:AddListener()
    self.BtnHeadSure.CallBack = function() self:OnBtnHeadSureClick() end
    self.BtnHeadCancel.CallBack = function() self:OnBtnHeadCancelClick() end
    self.BtnClose.CallBack = function() self:OnBtnHeadCancelClick() end
end

function XUiGuildViewSetHeadPortrait:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.ScrollView)
    self.DynamicTable:SetProxy(XUiGuildHeadPortraitItem)
    self.DynamicTable:SetDelegate(self)
    self.GameObject:SetActiveEx(false)
end

function XUiGuildViewSetHeadPortrait:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:OnRefresh(self.ListDatas[index])
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        if self.CurSeleGridItem then
            self.CurSeleGridItem:SetStatus(false)
        end

        local data = self.ListDatas[index]
        grid:SetStatus(true)
        self.CurSeleGridItem = grid
        self:UpdateInfo(data.Id)
    end
end

function XUiGuildViewSetHeadPortrait:OnRefresh(defaultHeadPortriatId)
    if defaultHeadPortriatId then
        self.InitHeadPortraitId = defaultHeadPortriatId
    end
    self:SetListDatas()
    self:UpdateInfo(self.InitHeadPortraitId)
end


function XUiGuildViewSetHeadPortrait:IsSeleId(id)
    return self.CurHeadPortraitId == id
end

function XUiGuildViewSetHeadPortrait:UpdateInfo(id)
    if self.CurHeadPortraitId == id then
        return
    end

    self.CurHeadPortraitId = id
    local config = XGuildConfig.GetGuildHeadPortraitById(id)
    self.RImgPlayerIcon:SetRawImage(config.Icon)
    self.TxtHeadName.text = config.Name
    self.TxtDecs.text = config.Describe
end

function XUiGuildViewSetHeadPortrait:SetListDatas()
    local list = XGuildConfig.GetGuildHeadPortraitDatas()
    if self.HideUnLock then
        local tmp = {}
        for _, data in ipairs(list or {}) do
            local conditionId = data.ConditionId
            if conditionId <= 0 then
                table.insert(tmp, data)
            else
                local unlock, _ = XConditionManager.CheckCondition(data.ConditionId)
                if unlock then
                    table.insert(tmp, data)
                end
            end
        end
        list = tmp
    end
    self.ListDatas = list
    self.DynamicTable:SetDataSource(self.ListDatas)
    self.DynamicTable:ReloadDataSync(1)
end

function XUiGuildViewSetHeadPortrait:OnBtnHeadSureClick()
    self.Parent:RecordGuildIconId(self.CurHeadPortraitId)
    self:OnBtnHeadCancelClick()
end

function XUiGuildViewSetHeadPortrait:RecordFirstSeleItem(item)
    self.CurSeleGridItem = item
end

function XUiGuildViewSetHeadPortrait:OnBtnHeadCancelClick()
    self.GameObject:SetActiveEx(false)
end
return XUiGuildViewSetHeadPortrait