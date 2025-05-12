---@class XUiBigWorldSet : XBigWorldUi
---@field BtnSave XUiComponent.XUiButton
---@field BtnDefault XUiComponent.XUiButton
---@field BtnBack XUiComponent.XUiButton
---@field BtnMainUi XUiComponent.XUiButton
---@field TabBtnGroup XUiButtonGroup
---@field BtnTab UnityEngine.RectTransform
---@field SafeAreaContentPanel XUiSafeAreaAdapter
---@field _Control XBigWorldSetControl
local XUiBigWorldSet = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldSet")

function XUiBigWorldSet:OnAwake()
    ---@type XBWSetTypeData[]
    self._TypeDatas = false

    self._TabList = {}

    self._SelectTypeIndex = 0

    self._TipTitle = XUiHelper.GetText("TipTitle")
    self._TipContent = XUiHelper.GetText("SettingCheckSave")

    self:_RegisterButtonClicks()
end

function XUiBigWorldSet:OnStart(setTypes)
    setTypes = setTypes or self._Control:GetDefaultSetTypes()
    self._TypeDatas = self._Control:GetSetTypeDatas(setTypes)

    self:_InitTabGroup()
end

function XUiBigWorldSet:OnEnable()
    self:_RegisterListeners()
    self:_RegisterSchedules()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldSet:OnDisable()
    self:_RemoveListeners()
    self:_RemoveSchedules()
end

function XUiBigWorldSet:OnDestroy()
end

function XUiBigWorldSet:OnBtnSaveClick()
    local currentTypeData = self._TypeDatas[self._SelectTypeIndex]

    if currentTypeData then
        self._Control:SaveSettingBySetType(currentTypeData:GetType())
    end
    XUiManager.TipText("SettingSave")
end

function XUiBigWorldSet:OnBtnDefaultClick()
    local currentTypeData = self._TypeDatas[self._SelectTypeIndex]

    if currentTypeData then
        self._Control:RestoreSettingBySetType(currentTypeData:GetType())
    end
end

function XUiBigWorldSet:OnBtnBackClick()
    local currentTypeData = self._TypeDatas[self._SelectTypeIndex]

    if currentTypeData then
        local currentType = currentTypeData:GetType()

        if self._Control:CheckSettingChangedBySetType(currentType) then
            self:_OpenConfirmDialog(function()
                self._Control:SaveSettingBySetType(currentType)
                self:Close()
            end, function()
                self._Control:ResetSettingBySetType(currentType)
                self:Close()
            end)

            return
        end
    end

    self:Close()
end

function XUiBigWorldSet:OnTabBtnGroupClick(index)
    if self._SelectTypeIndex ~= index then
        self:_TryChangePage(index)
    end
end

function XUiBigWorldSet:UpdateSpecialScreenOff()
    self.SafeAreaContentPanel:UpdateSpecialScreenOff()
end

function XUiBigWorldSet:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self.BtnSave.CallBack = Handler(self, self.OnBtnSaveClick)
    self.BtnDefault.CallBack = Handler(self, self.OnBtnDefaultClick)
    self.BtnBack.CallBack = Handler(self, self.OnBtnBackClick)
end

function XUiBigWorldSet:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiBigWorldSet:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiBigWorldSet:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldSet:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiBigWorldSet:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiBigWorldSet:_InitTabGroup()
    if not XTool.IsTableEmpty(self._TypeDatas) then
        self._TypeIndex = {}
        for i, typeData in ipairs(self._TypeDatas) do
            local tab = self._TabList[i]

            if not tab then
                tab = XUiHelper.Instantiate(self.BtnTab, self.TabBtnGroup.transform)

                self._TabList[i] = tab
            end

            tab.gameObject:SetActiveEx(true)
            tab:SetNameByGroup(0, typeData:GetName())
            tab:SetSprite(typeData:GetIcon())
        end

        self.TabBtnGroup:Init(self._TabList, Handler(self, self.OnTabBtnGroupClick))
        self.TabBtnGroup:SelectIndex(1)
    end

    self.BtnTab.gameObject:SetActiveEx(false)
end

function XUiBigWorldSet:_RefreshSubPage(index)
    local typeData = self._TypeDatas[index]

    if typeData then
        local uiName = typeData:GetUiName()

        self:OpenOneChildUi(uiName)
    end
end

function XUiBigWorldSet:_TryChangePage(index)
    local currentTypeData = self._TypeDatas[self._SelectTypeIndex]

    if currentTypeData then
        local currentType = currentTypeData:GetType()

        if self._Control:CheckSettingChangedBySetType(currentType) then
            self:_OpenConfirmDialog(function()
                self._Control:SaveSettingBySetType(currentType)
                self:_RefreshSubPage(index)
                self._SelectTypeIndex = index
            end, function()
                self._Control:ResetSettingBySetType(currentType)
                self:_RefreshSubPage(index)
                self._SelectTypeIndex = index
            end, function()
                self.TabBtnGroup:SelectIndex(self._SelectTypeIndex)
            end)
        else
            self:_RefreshSubPage(index)
            self._SelectTypeIndex = index
        end
    else
        self:_RefreshSubPage(index)
        self._SelectTypeIndex = index
    end
end

function XUiBigWorldSet:_OpenConfirmDialog(confirmCallback, cancelCallback, closeCallback)
    local dialogData = XMVCA.XBigWorldCommon:GetPopupConfirmData()

    dialogData:InitInfo(self._TipTitle, self._TipContent)
    dialogData:InitSureClick(nil, confirmCallback, true):InitToggleActive(false)
    if closeCallback then
        dialogData:InitCloseClick(nil, closeCallback, true)
        dialogData:InitCancelClick(nil, cancelCallback, true)
    else
        dialogData:InitCancelAndCloseClick(nil, cancelCallback, true)
    end

    XMVCA.XBigWorldUI:OpenConfirmPopup(dialogData)
end

return XUiBigWorldSet
