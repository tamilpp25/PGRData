--虚像地平线招募界面招募商店角色列表控件
local XUiExpeditionRecruitShopPanel = XClass(nil, "XUiExpeditionRecruitShopPanel")
local XUiExpeditionRecruitShopGrid = require("XUi/XUiExpedition/Recruit/XUiExpeditionRoomChar/XUiExpeditionRecruitShopGrid")
function XUiExpeditionRecruitShopPanel:Ctor(ui, rootUi, models)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.GridSample = rootUi.GridRoomChar
    self.GridSample.gameObject:SetActiveEx(false)
    self.Model3D = models
    self.GridNum = XDataCenter.ExpeditionManager.GetRecruitDrawNum()
    self:InitPanel()
end

function XUiExpeditionRecruitShopPanel:InitPanel()
    self.CharaGrids = {}
    for i = 1, self.GridNum do
        local roomCharCase = self.Transform:FindTransform("RoomCharCase" .. i)
        if roomCharCase then
            local prefab = CS.UnityEngine.Object.Instantiate(self.GridSample.gameObject)
            prefab.transform:SetParent(roomCharCase, false)
            prefab.gameObject:SetActiveEx(true)
            self.CharaGrids[i] = XUiExpeditionRecruitShopGrid.New(prefab, self.Model3D[i], self.RootUi, i)
            CsXUiHelper.RegisterClickEvent(self.CharaGrids[i].BtnRecruit, function() self.CharaGrids[i]:OnClick() end)
            CsXUiHelper.RegisterClickEvent(self.CharaGrids[i].BtnRankUp, function() self.CharaGrids[i]:OnClick() end)
        end
    end
end

function XUiExpeditionRecruitShopPanel:UpdateData(playEffect)
    local recruitMembers = XDataCenter.ExpeditionManager.GetRecruitMembers()
    for i = 1, self.GridNum do
        if recruitMembers and recruitMembers:GetCharaByPos(i) then
            self.CharaGrids[i]:RefreshDatas(i, playEffect)
        else
            self.CharaGrids[i]:RefreshDatas(nil)
        end
    end
end
return XUiExpeditionRecruitShopPanel