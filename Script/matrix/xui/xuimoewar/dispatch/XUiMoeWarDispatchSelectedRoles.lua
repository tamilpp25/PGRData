local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridHelper = require("XUi/XUiMoeWar/ChildItem/XUiGridHelper")

--选择派遣角色弹窗
local XUiMoeWarDispatchSelectedRoles = XLuaUiManager.Register(XLuaUi, "UiMoeWarDispatchSelectedRoles")

function XUiMoeWarDispatchSelectedRoles:OnAwake()
    self:AddListener()
    self:InitDynamicTable()
end

function XUiMoeWarDispatchSelectedRoles:OnStart(data)
    self.CurSelectHelperId = data.CurSelectHelperId --当前选择的角色Id
    self.SelectHelperCb = data.SelectHelperCb       --选择角色回调
    self.StageId = data.StageId                     --选择的关卡Id
end

function XUiMoeWarDispatchSelectedRoles:OnEnable()
    local helperIdList = XDataCenter.MoeWarManager.GetAllOwnHelpersList()
    self.CurSelectHelperId = self.CurSelectHelperId or helperIdList[1]
    self:Refresh()
end

function XUiMoeWarDispatchSelectedRoles:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelSelectList)
    self.DynamicTable:SetProxy(XUiGridHelper)
    self.DynamicTable:SetDelegate(self)
    self.DormSelectItem.gameObject:SetActiveEx(false)
end

function XUiMoeWarDispatchSelectedRoles:AddListener()
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self:RegisterClickEvent(self.BtnCancel, self.Close)
    self:RegisterClickEvent(self.BtnTanchuangClose, self.Close)
    self:RegisterClickEvent(self.BtnConfirm, self.OnBtnConfirmClick)
end

function XUiMoeWarDispatchSelectedRoles:Refresh()
    self:UpdateDynamicTable()
end

function XUiMoeWarDispatchSelectedRoles:UpdateDynamicTable()
    self.HelperIdList = XDataCenter.MoeWarManager.GetAllOwnHelpersList()
    self.DynamicTable:SetDataSource(self.HelperIdList)
    self.DynamicTable:ReloadDataASync()
    self.ImgNonePerson.gameObject:SetActiveEx(XTool.IsTableEmpty(self.HelperIdList))
end

function XUiMoeWarDispatchSelectedRoles:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local helperId = self.HelperIdList[index]
        grid:Refresh({HelperId = helperId, StageId = self.StageId})

        local isCurSelectHelper = self.CurSelectHelperId == grid:GetHelperId()
        grid:SetImgSelectActive(isCurSelectHelper)
        if isCurSelectHelper then
            self.CurSelectGrid = grid
        end

    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local helperId = self.HelperIdList[index]
        if self.CurSelectHelperId == helperId then
            return
        end
        self.CurSelectHelperId = helperId
        if self.CurSelectGrid then
            self.CurSelectGrid:SetImgSelectActive(false)
        end
        grid:SetImgSelectActive(true)
        self.CurSelectGrid = grid
    end
end

function XUiMoeWarDispatchSelectedRoles:OnBtnConfirmClick()
    if self.SelectHelperCb then
        self.SelectHelperCb(self.CurSelectHelperId)
    end
    self:Close()
end