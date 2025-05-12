local XUiGridArchive = require("XUi/XUiArchive/XUiGridArchive")

--
-- Author: wujie
-- Note: 图鉴武器成就系统

local XUiArchiveWeaponAchievement = XLuaUiManager.Register(XLuaUi, "UiArchiveWeaponAchievement")

local XUiGridArchiveWeaponAchievement = require("XUi/XUiArchive/XUiGridArchiveWeaponAchievement")

function XUiArchiveWeaponAchievement:OnAwake()
    self.GridCollectionList = {
        XUiGridArchiveWeaponAchievement.New(self.GridCollection1,self),
        XUiGridArchiveWeaponAchievement.New(self.GridCollection2,self),
        XUiGridArchiveWeaponAchievement.New(self.GridCollection3,self),
    }
    for _, grid in ipairs(self.GridCollectionList) do
        grid:SetClickCallback(handler(self, self.OnGridClick))
    end

    self:AutoAddListener()
end

function XUiArchiveWeaponAchievement:OnStart(parent)
    self.Parent = parent
end

function XUiArchiveWeaponAchievement:OnEnable()
    if not self.Parent then return end
    local type = self.Parent.BtnGroupTypeList[self.Parent.FirstHierarchyFilterSelectIndex]
    local idList = self._Control:GetWeaponTemplateIdListByType(type)
    local haveCollectNum = 0
    for _, templateId in pairs(idList) do
        if XMVCA.XArchive:IsWeaponGet(templateId) then
            haveCollectNum = haveCollectNum + 1
        end
    end

    local groupData = XMVCA.XArchive:GetWeaponGroupByType(type)
    local achievementNum = #groupData.CollectNum

    for i, grid in ipairs(self.GridCollectionList) do
        if i > achievementNum then
            grid.GameObject:SetActiveEx(false)
        else
            grid.GameObject:SetActiveEx(true)
            grid:Refresh(groupData, i, haveCollectNum)
        end
    end
end

function XUiArchiveWeaponAchievement:AutoAddListener()
    self.BtnClose.CallBack = function() self:Close() end
    self.BtnBg.CallBack = function() self:Close() end
end

-----------------------------------事件相关----------------------------------------->>>
function XUiArchiveWeaponAchievement:OnGridClick(cgId)
    if cgId and cgId ~= 0 then
        XDataCenter.MovieManager.PlayMovie(cgId)
    end
end
-----------------------------------事件相关-----------------------------------------<<<