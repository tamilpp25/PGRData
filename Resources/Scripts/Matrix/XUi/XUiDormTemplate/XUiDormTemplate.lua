local XUiDormTemplate = XLuaUiManager.Register(XLuaUi, "UiDormTemplate")
local XUiGridDormTemplate = require("XUi/XUiDormTemplate/XUiGridDormTemplate")
local DEFLUAT_INDEX = 1

function XUiDormTemplate:OnAwake()
    self:AddListener()
    self:BtnTableDisable()
end

function XUiDormTemplate:OnStart(selectIndex, enterSenceCb, curDormId)
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset,
    XDataCenter.ItemManager.ItemId.DormCoin,
    XDataCenter.ItemManager.ItemId.FurnitureCoin,
    XDataCenter.ItemManager.ItemId.DormEnterIcon)

    self.EnterSenceCb = enterSenceCb
    self.CurSelectIndex = selectIndex or DEFLUAT_INDEX
    self.CurDormId = curDormId
    self:InitDynamicTable()
    self:SetTog()
end

function XUiDormTemplate:OnEnable()
    self:OnSelectedTog(self.CurSelectIndex)
end

function XUiDormTemplate:AddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:BindHelpBtn(self.BtnHelp, "DormTemplate")
end

function XUiDormTemplate:BtnTableDisable()
    self.BtnFirst.gameObject:SetActiveEx(false)
    self.BtnFirstHasSnd.gameObject:SetActiveEx(false)
    self.BtnSecondTop.gameObject:SetActiveEx(false)
    self.BtnSecond.gameObject:SetActiveEx(false)
    self.BtnSecondBottom.gameObject:SetActiveEx(false)
    self.BtnSecondAll.gameObject:SetActiveEx(false)
end

function XUiDormTemplate:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiDormTemplate:OnBtnBackClick()
    self:Close()
end

function XUiDormTemplate:SetTog()
    self.InfoList = XDormConfig.GetDormTemplateGroupList()
    self.BtnGoList = {}
    for _, info in ipairs(self.InfoList) do
        local btn
        if info.SecondIndex <= 0 then
            if info.HasScond then
                btn = CS.UnityEngine.Object.Instantiate(self.BtnFirstHasSnd.gameObject)
            else
                btn = CS.UnityEngine.Object.Instantiate(self.BtnFirst.gameObject)
            end
        else
            if info.SecondTagType == XShopManager.SecondTagType.Top then
                btn = CS.UnityEngine.Object.Instantiate(self.BtnSecondTop.gameObject)
            elseif info.SecondTagType == XShopManager.SecondTagType.Mid then
                btn = CS.UnityEngine.Object.Instantiate(self.BtnSecond.gameObject)
            elseif info.SecondTagType == XShopManager.SecondTagType.Btm then
                btn = CS.UnityEngine.Object.Instantiate(self.BtnSecondBottom.gameObject)
            else
                btn = CS.UnityEngine.Object.Instantiate(self.BtnSecondAll.gameObject)
            end
        end

        btn.gameObject.transform:SetParent(self.BtnTogs.gameObject.transform, false)
        local uiButton = btn:GetComponent("XUiButton")
        uiButton.SubGroupIndex = info.SecondIndex
        uiButton:SetName(info.Name)
        table.insert(self.BtnGoList, uiButton)
        btn.gameObject:SetActiveEx(true)
    end

    self.BtnTogs:Init(self.BtnGoList, function(index)
        self:OnSelectedTog(index)
    end)

    self.BtnTogs:SelectIndex(self.CurSelectIndex)
end

function XUiDormTemplate:OnSelectedTog(index)
    self:PlayAnimation("QieHuan")

    self.CurSelectIndex = index
    local teamplateInfo = self.InfoList[index]
    self.PageDatas = {}
    self.RoomType = teamplateInfo.DormType

    if self.RoomType == XDormConfig.DormDataType.Template then
        self.PageDatas = XDataCenter.DormManager.GetTemplateDormitoryData(XDormConfig.DormDataType.Template, teamplateInfo.DormId)
    elseif self.RoomType == XDormConfig.DormDataType.Collect then
        local datas = XDataCenter.DormManager.GetTemplateDormitoryData(XDormConfig.DormDataType.Collect)
        local collectCfgs = XDormConfig.GetDormTemplateCollectList()

        for i = 1, #collectCfgs do
            local tempDate = {}
            if i > #datas then
                tempDate.HomeRoomData = nil
            else
                tempDate.HomeRoomData = datas[i]
            end
            tempDate.CollectCfg = collectCfgs[i]
            table.insert(self.PageDatas, tempDate)
        end
    end

    self:SetupDynamicTable()
end

function XUiDormTemplate:InitDynamicTable()
    self.GridDormTemplate.gameObject:SetActiveEx(false)
    self.DynamicTable = XDynamicTableNormal.New(self.PanelDynamicTable)
    self.DynamicTable:SetProxy(XUiGridDormTemplate)
    self.DynamicTable:SetDelegate(self)
end

function XUiDormTemplate:SetupDynamicTable()
    self.DynamicTable:SetDataSource(self.PageDatas)
    self.DynamicTable:ReloadDataSync(1)
end

-- 动态列表事件
function XUiDormTemplate:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self.RoomType == XDormConfig.DormDataType.Template then
            grid:Refresh(self.PageDatas[index], self.RoomType, nil, self.EnterSenceCb, self.CurDormId)
        elseif self.RoomType == XDormConfig.DormDataType.Collect then
            local d = self.PageDatas[index]
            grid:Refresh(d.HomeRoomData, self.RoomType, d.CollectCfg, self.EnterSenceCb)
        end
    end
end