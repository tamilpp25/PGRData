---@class XUiGridMonsterRole
---@field RImgHeadIcon UnityEngine.UI.RawImage
local XUiGridMonsterRole = XClass(nil, "XUiGridMonsterRole")

---@param rootUi XUiMonsterCombatRoleList
function XUiGridMonsterRole:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self.GridImgStarList = {}
end

function XUiGridMonsterRole:Refresh(monsterId)
    self.MonsterId = monsterId
    self.MonsterEntity = XDataCenter.MonsterCombatManager.GetMonsterEntity(monsterId)
    self:RefreshMonsterView()
    self:RefreshMonsterStatus()
end

function XUiGridMonsterRole:RefreshMonsterView()
    -- 头像
    self.RImgHeadIcon:SetRawImage(self.MonsterEntity:GetAchieveIcon())
    -- 名称
    self.TxtName.text = self.MonsterEntity:GetName()
    -- 负重
    local cost = self.MonsterEntity:GetCost()
    for i = 1, cost do
        local grid = self.GridImgStarList[i]
        if not grid then
            grid = i == 1 and self.ImgStar or XUiHelper.Instantiate(self.ImgStar, self.PanelStars)
            self.GridImgStarList[i] = grid
        end
        grid.gameObject:SetActiveEx(true)
    end
    for i = cost + 1, #self.GridImgStarList do
        self.GridImgStarList[i].gameObject:SetActiveEx(false)
    end
    -- 解锁条件
    self.TxtLockDesc.text = XUiHelper.GetText("UiMonsterCombatMonsterNotUnlock")
end

function XUiGridMonsterRole:RefreshMonsterStatus()
    local isUnlock = self.MonsterEntity:CheckIsUnlock()
    self.PanelUnLock.gameObject:SetActiveEx(isUnlock)
    self.PanelLock.gameObject:SetActiveEx(not isUnlock)
end

-- 选择
function XUiGridMonsterRole:SetSelectStatus(value)
    if self.PanelSelected then
        self.PanelSelected.gameObject:SetActiveEx(value)
    end
end

-- 队伍
function XUiGridMonsterRole:SetInTeamStatus(value)
    if self.ImgInTeam then
        self.ImgInTeam.gameObject:SetActiveEx(value)
    end
end

-- 推荐
function XUiGridMonsterRole:SetInRecommendStatus(value)
    if self.ImgRecommend then
        self.ImgRecommend.gameObject:SetActiveEx(value)
    end
end

-- 羁绊
function XUiGridMonsterRole:SetInFetterStatus(value)
    if self.ImgLove then
        self.ImgLove.gameObject:SetActiveEx(value)
    end
end

-- 红点
function XUiGridMonsterRole:RefreshRedPoint(value)
    if self.Red then
        self.Red.gameObject:SetActiveEx(value)
    end
end

return XUiGridMonsterRole