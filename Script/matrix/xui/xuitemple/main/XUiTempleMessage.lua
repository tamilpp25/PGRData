local XUiTempleMessageGrid = require("XUi/XUiTemple/Main/XUiTempleMessageGrid")

---@class XUiTempleMessage : XLuaUi
---@field _Control XTempleControl
local XUiTempleMessage = XLuaUiManager.Register(XLuaUi, "UiTempleMessage")

function XUiTempleMessage:OnAwake()
    self:RegisterClickEvent(self.BtnTanchuangClose, self.Close)
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self:InitDynamicTable()
    self.GridMessage.gameObject:SetActiveEx(false)
    self.Notopen = self.Notopen or XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/RImgBg/Notopen", "Transform")
    self.Txt01 = self.Txt01 or XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/Notopen/ImgBg/Txt01", "Transform")
    self.Txt02 = self.Txt02 or XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/Notopen/ImgBg/Txt02", "Transform")
end

function XUiTempleMessage:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelMessage)
    self.DynamicTable:SetProxy(XUiTempleMessageGrid, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiTempleMessage:OnEnable()
    self:Update()
end

function XUiTempleMessage:Update()
    local data = self._Control:GetUiControl():GetDataMessage()
    if #data == 0 then
        self.Notopen.gameObject:SetActiveEx(true)
        if self._Control:IsSpringChapter() then
            self.Txt01.gameObject:SetActiveEx(true)
            self.Txt02.gameObject:SetActiveEx(false)
        elseif self._Control:IsLanternChapter() then
            self.Txt01.gameObject:SetActiveEx(false)
            self.Txt02.gameObject:SetActiveEx(true)
        else
            self.Txt01.gameObject:SetActiveEx(false)
            self.Txt02.gameObject:SetActiveEx(false)
        end
    else
        self.Notopen.gameObject:SetActiveEx(false)
    end
    self.DynamicTable:SetDataSource(data)
    self.DynamicTable:ReloadDataSync()

    self.TxtTiTle.text = XUiHelper.GetText("TempleMessage" .. self._Control:GetChapter())
end

function XUiTempleMessage:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Update(self.DynamicTable:GetData(index))
    end
end

return XUiTempleMessage