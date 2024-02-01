local XUiGridAreaWarSpecialRole = require("XUi/XUiAreaWar/XUiGridAreaWarSpecialRole")
local XUiGridAreaWarSpecialRoleReward = require("XUi/XUiAreaWar/XUiGridAreaWarSpecialRoleReward")

local XUiAreaWarSpecialRole = XLuaUiManager.Register(XLuaUi, "UiAreaWarSpecialRole")

function XUiAreaWarSpecialRole:OnAwake()
    self.GridCourse.gameObject:SetActiveEx(false)
    self.GridSpecialRole.gameObject:SetActiveEx(false)
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool, self)
    XDataCenter.ItemManager.AddCountUpdateListener(
        {
            XDataCenter.ItemManager.ItemId.AreaWarCoin,
            XDataCenter.ItemManager.ItemId.AreaWarActionPoint
        },
        handler(self, self.UpdateAssets),
        self.AssetActivityPanel
    )
    self.DynamicTable = XDynamicTableNormal.New(self.SViewCourse)
    self.DynamicTable:SetProxy(XUiGridAreaWarSpecialRoleReward)
    self.DynamicTable:SetDelegate(self)

    self:AutoAddListener()
end

function XUiAreaWarSpecialRole:OnStart(chapterId)
    self.ChapterIds = XAreaWarConfigs.GetChapterIds()
    chapterId = chapterId or XDataCenter.AreaWarManager.GetBranchNewChapterId()
    self.SelectIndex = self:GetBtnIndexByAreaId(chapterId)
    self.RewardIds = XAreaWarConfigs.GetAllSpecialRoleUnlockRewardIds()
    self.Btns = {}
    self.RoleGridList = {}
    self:InitView()
end

function XUiAreaWarSpecialRole:OnEnable()
    if self.IsEnd then
        return
    end
    if XDataCenter.AreaWarManager.OnActivityEnd() then
        self.IsEnd = true
        return
    end

    self:UpdateAssets()
    self:UpdateAreas()
    self:UpdateRewardProgress()

    self.SkipAnim = true
    self.PanelTabGroup:SelectIndex(self.SelectIndex)
end

function XUiAreaWarSpecialRole:OnGetEvents()
    return {
        XEventId.EVENT_AREA_WAR_SPECIAL_ROLE_REWARD_GOT,
        XEventId.EVENT_AREA_WAR_ACTIVITY_END
    }
end

function XUiAreaWarSpecialRole:OnNotify(evt, ...)
    if self.IsEnd then
        return
    end

    local args = {...}
    if evt == XEventId.EVENT_AREA_WAR_SPECIAL_ROLE_REWARD_GOT then
        self:UpdateRewardProgress()
    elseif evt == XEventId.EVENT_AREA_WAR_ACTIVITY_END then
        if XDataCenter.AreaWarManager.OnActivityEnd() then
            self.IsEnd = true
            return
        end
    end
end

function XUiAreaWarSpecialRole:AutoAddListener()
    self:BindHelpBtn(self.BtnHelp, "AreaWarSpecialRole")
    self.BtnBack.CallBack = function()
        self:Close()
    end
    self.BtnMainUi.CallBack = function()
        XLuaUiManager.RunMain()
    end
end

function XUiAreaWarSpecialRole:InitView()
    self.TxtTips.text = CsXTextManagerGetText("AreaWarSpecialRoleTips")

    for index, chapterId in ipairs(self.ChapterIds) do
        local btn = self.Btns[index]
        if not btn then
            local go =
                index == 1 and self.BtnFirst or
                CSObjectInstantiate(self.BtnFirst.gameObject, self.PanelTabGroup.transform)
            btn = go:GetComponent("XUiButton")
            self.Btns[index] = btn
        end
    end
    self.PanelTabGroup:Init(
        self.Btns,
        function(index)
            self:OnClickTabBtn(index)
        end
    )
end

function XUiAreaWarSpecialRole:UpdateAssets()
    self.AssetActivityPanel:Refresh(
        {
            XDataCenter.ItemManager.ItemId.AreaWarCoin,
            XDataCenter.ItemManager.ItemId.AreaWarActionPoint
        },
        {
            XDataCenter.ItemManager.ItemId.AreaWarActionPoint
        }
    )
end

function XUiAreaWarSpecialRole:UpdateAreas()
    for index, chapterId in ipairs(self.ChapterIds) do
        local btn = self.Btns[index]
        if btn then
            local chapterName = XAreaWarConfigs.GetChapterName(chapterId)
            btn:SetNameByGroup(0, chapterName)

            local tipStr = ""
            local isUnlock = XDataCenter.AreaWarManager.IsChapterUnlock(chapterId)
            if isUnlock then
                local unlockCount, totalCount = XDataCenter.AreaWarManager.GetAreaSpecialRolesUnlockProgress(chapterId)
                tipStr = CsXTextManagerGetText("AreaWarAreaSpeicalRoleUnlockProgress", unlockCount, totalCount)
            else
                local leftTime = XDataCenter.AreaWarManager.GetChapterUnlockLeftTime(chapterId)
                if leftTime > 0 then
                    tipStr =
                        CsXTextManagerGetText(
                        "AreaWarAreaUnlockLeftTime",
                        XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.AREA_WAR_AREA_UNLOCK)
                    )
                else
                    tipStr = CsXTextManagerGetText("AreaWarAreaLock")
                end
            end

            btn:SetDisable(not isUnlock, isUnlock)
            btn:SetNameByGroup(1, tipStr)
        end
    end
end

function XUiAreaWarSpecialRole:OnClickTabBtn(index)
    local isUnlock = XDataCenter.AreaWarManager.IsChapterUnlock(self.ChapterIds[index])
    if not isUnlock then
        return
    end
    self.SelectIndex = index
    self:UpdateSpecialRoles()

    if self.SkipAnim then
        self.SkipAnim = nil
    else
        self:PlayAnimation("QieHuan")
    end
end

function XUiAreaWarSpecialRole:UpdateSpecialRoles()
    local areaId = self:GetChapterId()
    local roleIds = XAreaWarConfigs.GetChapterSpecialRoleIds(areaId)
    for index, roleId in ipairs(roleIds) do
        local grid = self.RoleGridList[index]
        if not grid then
            local go =
                index == 1 and self.GridSpecialRole or CSObjectInstantiate(self.GridSpecialRole, self.PanelContent)
            local clickCb = handler(self, self.OnClickRole)
            grid = XUiGridAreaWarSpecialRole.New(go, clickCb)
            self.RoleGridList[index] = grid
        end
        grid:Refresh(roleId)
        grid.GameObject:SetActiveEx(true)
    end
    for index = #roleIds + 1, #self.RoleGridList do
        self.RoleGridList[index].GameObject:SetActiveEx(false)
    end
end

function XUiAreaWarSpecialRole:OnClickRole(roleId)
    local chapterId = self:GetChapterId()
    local roleIds = XAreaWarConfigs.GetChapterSpecialRoleIds(chapterId)
    for index, grid in pairs(self.RoleGridList) do
        grid:SetSelect(roleId == roleIds[index])
    end
    XLuaUiManager.Open(
        "UiAreaWarSpecialRolePopUp",
        roleId,
        function()
            for index, grid in pairs(self.RoleGridList) do
                grid:SetSelect(false)
            end
        end
    )
end

function XUiAreaWarSpecialRole:UpdateRewardProgress()
    local unlockCount, totalCount = XDataCenter.AreaWarManager.GetSpecialRoleProgress()
    self.TxtCurProgress.text = unlockCount
    self.TxtTotalProgress.text = "/" .. totalCount

    --全部未达成，滑到最左
    --有已领取的，则上滑到已领取里档位最高的在最左第一格，直到无法再右滑
    --当期活动策划不需要这个功能了
    --local selectIndex = -1
    --for index = #self.RewardIds, 1, -1 do
    --    if XDataCenter.AreaWarManager.IsSpecialRoleRewardHasGot(self.RewardIds[index]) then
    --        selectIndex = index
    --        break
    --    end
    --end
    self.DynamicTable:SetDataSource(self.RewardIds)
    --self.DynamicTable:ReloadDataSync(selectIndex)
    self.DynamicTable:ReloadDataSync()
end

function XUiAreaWarSpecialRole:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid.RootUi = self
        grid.ClickCb = function(rewardId)
            self:OnClickSpecialRoleReward(rewardId)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.RewardIds[index])
    end
end

function XUiAreaWarSpecialRole:OnClickSpecialRoleReward(rewardId)
    local hasGot = XDataCenter.AreaWarManager.IsSpecialRoleRewardHasGot(rewardId)
    if hasGot then
        XUiManager.TipText("AreaWarAreaSpecialRoleRewardGot")
        return
    end

    local canGet = XDataCenter.AreaWarManager.IsSpecialRoleRewardCanGet(rewardId)
    if not canGet then
        local realRewardId = XAreaWarConfigs.GetSpecialRoleRewardRewardId(rewardId)
        local rewardData = XRewardManager.GetRewardList(realRewardId)
        XLuaUiManager.Open("UiTip", rewardData[1])
    else
        XDataCenter.AreaWarManager.AreaWarGetSpecialRoleRewardRequest(
            rewardId,
            function(rewardGoodsList)
                if not XTool.IsTableEmpty(rewardGoodsList) then
                    XUiManager.OpenUiObtain(rewardGoodsList)
                end
            end
        )
    end
end

function XUiAreaWarSpecialRole:GetChapterId()
    return self.ChapterIds[self.SelectIndex]
end

function XUiAreaWarSpecialRole:GetBtnIndexByAreaId(areaId)
    for index, inAreaId in pairs(self.ChapterIds) do
        if inAreaId == areaId then
            return index
        end
    end
end
