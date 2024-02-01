--
-- Author: wujie
-- Note: 图鉴武器成就格子
local XUiGridArchiveWeaponAchievement = XClass(XUiNode, "XUiGridArchiveWeaponAchievement")

local StoryUncollectedDescStr = CS.XTextManager.GetText("ArchiveWeaponAchievementStoryUncollectedDesc")
local StoryCollectedDescStr = CS.XTextManager.GetText("ArchiveWeaponAchievementStoryCollectedDesc")

function XUiGridArchiveWeaponAchievement:OnStart()
    -- self.RootUi = rootUi
    -- self.ClickCb = clickCb

    self.BtnClick.CallBack = function() self:OnBtnClick() end
end

function XUiGridArchiveWeaponAchievement:InitRootUi(rootUi)
    self.RootUi = rootUi
end

function XUiGridArchiveWeaponAchievement:SetClickCallback(callback)
    self.ClickCb = callback
end

function XUiGridArchiveWeaponAchievement:SetGetState(isGet)
    if not self.GroupData or not self.Index then return end
    if isGet then
        self.RImgCollectedIcon.gameObject:SetActiveEx(true)
        self.RImgUncollectedIcon.gameObject:SetActiveEx(false)
        self.RImgCollectedIcon:SetRawImage(self.GroupData.IconPath[self.Index])
    else
        self.RImgCollectedIcon.gameObject:SetActiveEx(false)
        self.RImgUncollectedIcon.gameObject:SetActiveEx(true)
        self.RImgUncollectedIcon:SetRawImage(self.GroupData.IconPath[self.Index])
    end
    self.ImgLock.gameObject:SetActiveEx(not isGet)
    self.ImgFinish.gameObject:SetActiveEx(isGet)
end

function XUiGridArchiveWeaponAchievement:SetStory(CgId)
    if not CgId or CgId == 0 then
        self.TxtStory.gameObject:SetActiveEx(false)
    else
        self.TxtStory.gameObject:SetActiveEx(true)
        if self.IsGet then
            self.TxtStory.text = StoryCollectedDescStr
        else
            self.TxtStory.text = StoryUncollectedDescStr
        end
    end
end

function XUiGridArchiveWeaponAchievement:Refresh(groupData, index, haveCollectNum)
    self.GroupData = groupData
    self.Index = index

    self.TxtTitle.text = groupData.CollectionTitle[index]
    self.TxtContent.text = groupData.CollectionContent[index]

    local needCollectNum = groupData.CollectNum[index]
    haveCollectNum = math.min(haveCollectNum, needCollectNum)
    local isGet = haveCollectNum == needCollectNum
    self.IsGet = isGet
    if isGet then
        self.TxtBlueHaveCollectNum.gameObject:SetActiveEx(true)
        self.TxtRedHaveCollectNum.gameObject:SetActiveEx(false)
        self.TxtBlueHaveCollectNum.text = haveCollectNum
    else
        self.TxtBlueHaveCollectNum.gameObject:SetActiveEx(false)
        self.TxtRedHaveCollectNum.gameObject:SetActiveEx(true)
        self.TxtRedHaveCollectNum.text = haveCollectNum
    end
    self.TxtNeedCollectNum.text = needCollectNum

    self:SetGetState(isGet)
    self:SetStory(groupData.CgId[index])
end

-----------------------------------事件相关-----------------------------------------<<<
function XUiGridArchiveWeaponAchievement:OnBtnClick()
    if self.ClickCb and self.GroupData and self.IsGet then
        self.ClickCb(self.GroupData.CgId[self.Index], self)
    end
end
-----------------------------------事件相关----------------------------------------->>>
return XUiGridArchiveWeaponAchievement