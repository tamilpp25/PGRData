local XUiDormFieldGuideDesListItem = require("XUi/XUiDormFieldGuide/XUiDormFieldGuideDesListItem")
local XUiDormFieldGuideDes = XLuaUiManager.Register(XLuaUi, "UiDormFieldGuideDes")

function XUiDormFieldGuideDes:OnAwake()
    self:AddListener()
    self:InitList()
end

function XUiDormFieldGuideDes:AddListener()
    self:RegisterClickEvent(self.BtnTanchuangClose, self.OnBtnClick)
end

function XUiDormFieldGuideDes:OnBtnClick()
    self:PlayAnimation("PanelDesDisable", function()
        self:Close()
    end)
end

-- 更新数据
function XUiDormFieldGuideDes:OnStart(furnitureCfg)
    if not furnitureCfg then
        return
    end
    self:PlayAnimation("PanelDesEnable")
    self.TxtName.text = furnitureCfg.Name or ""
    self.TxtSuit.text = XFurnitureConfigs.GetFurnitureSuitName(furnitureCfg.SuitId) or ""
    self.TxtDes.text = furnitureCfg.Desc or ""
    local iconpath = furnitureCfg.Icon
    if iconpath then
        self:SetUiSprite(self.ImgIcon, iconpath)
    end

    local randomGroupId = furnitureCfg.RandomGroupId
    if self.PrerandomGroupId ~= randomGroupId then
        self.PrerandomGroupId = randomGroupId
        local d = XFurnitureConfigs.GetGroupRandomIntroduce(randomGroupId, true) or {}

        local listdata = {}

        if furnitureCfg.SuitId > 0 then
            local suitBgmInfo = XDormConfig.GetDormSuitBgmInfo(furnitureCfg.SuitId)
            if suitBgmInfo then
                table.insert(listdata, CS.XGame.ClientConfig:GetString("DormSuitBgmTitleDesc"))
                local suitDesc = string.format(CS.XGame.ClientConfig:GetString("DormSuitBgmDesc"), suitBgmInfo.SuitNum, "", suitBgmInfo.Name)
                table.insert(listdata, suitDesc)
            end
        end

        for k1, v1 in pairs(d) do
            table.insert(listdata, k1)
            for _, v2 in pairs(v1) do
                table.insert(listdata, v2.Introduce)
            end
        end

        self.ListData = listdata
        self.DynamicTable:SetDataSource(listdata)
        self.DynamicTable:ReloadDataASync(1)
    end
end

function XUiDormFieldGuideDes:InitList()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelDesList)
    self.DynamicTable:SetProxy(XUiDormFieldGuideDesListItem)
    self.DynamicTable:SetDelegate(self)
end

-- [监听动态列表事件]
function XUiDormFieldGuideDes:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.ListData[index]
        grid:OnRefresh(data)
    end
end