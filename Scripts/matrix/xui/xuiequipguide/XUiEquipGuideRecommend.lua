local XUiGridEquipGuide = require("XUi/XUiEquipGuide/XUiGridEquipGuide")
local XUiEquipRecommendItem = XClass(nil, "XUiEquipRecommendItem")

function XUiEquipRecommendItem:Ctor(ui, playAnimationCb, addVoteCb)
    XTool.InitUiObjectByUi(self, ui)
    self:InitCb()
    self.PlayAnimationCb = playAnimationCb
    self.AddVoteCb = addVoteCb
    self.GirdItems = {}
end

function XUiEquipRecommendItem:Refresh(target, isHideSetTarget)
    self.Target = target
    --目标是否达成
    self.PanelReach.gameObject:SetActiveEx(target:GetProperty("_IsFinish"))
    self.RecommendId = target:GetProperty("_RecommendId")
    local template = XCharacterConfigs.GetCharDetailEquipTemplate(self.RecommendId)
    --目标描述
    local targetId = target:GetProperty("_Id")
    self.TxtName.text = XEquipGuideConfigs.TargetConfig:GetProperty(targetId, "Description")
    --点赞
    self:RefreshVote()
    --是否是当前目标
    local isTarget = XDataCenter.EquipGuideManager.IsCurrentEquipTarget(targetId)
    --检查当前角色穿戴装备是否跟模板一致
    local isFullEquipped = self.Target:CheckIsFullEquipped()
    local isSetTarget = XDataCenter.EquipGuideManager.IsSetEquipTarget()
    local openSetTarget = XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.EquipGuideSetTarget) and not isHideSetTarget
    self.BtnSet.gameObject:SetActiveEx(openSetTarget)
    if openSetTarget then
        local disable = isTarget or (isFullEquipped and not isSetTarget)
        self.BtnSet:SetDisable(disable, not disable)
        if isTarget then
            self.BtnSet:SetNameByGroup(0, XUiHelper.GetText("EquipGuideCurTargetText"))
        elseif isFullEquipped and not isSetTarget then
            self.BtnSet:SetNameByGroup(0,  XUiHelper.GetText("EquipGuideEquippedText"))
        else
            self.BtnSet:SetNameByGroup(0,  XUiHelper.GetText("EquipGuideNoTargetText"))
        end
    end
    --装备
    self.WeaponGrid = self.WeaponGrid or XUiGridEquipGuide.New(self.GridEquipItem)
    self.WeaponGrid:Refresh(template.EquipRecomend, XEquipGuideConfigs.EquipType.Weapon)
    --意识
    local suitIds, numbers = template.SuitId, template.Number
    if not XTool.IsTableEmpty(suitIds) then
        for i, suitId in ipairs(suitIds) do
            local number = numbers[i]
            local grid = self.GirdItems[i]
            if not grid then
                local ui = i == 1 and self.GridItem
                        or CS.UnityEngine.Object.Instantiate(self.GridItem, self.RootPanelLayout, false)
                grid = XUiGridEquipGuide.New(ui)
                grid.GameObject:SetActiveEx(true)
                self.GirdItems[i] = grid
            end
            grid:Refresh(suitId, XEquipGuideConfigs.EquipType.Suit, number)
        end
    end

    XRedPointManager.CheckOnce(self.OnCheckHasStrongerWeapon, self,
            { XRedPointConditions.Types.CONDITION_EQUIP_GUIDE_HAS_STRONGER_WEAPON },
            self.Target
    )
end

function XUiEquipRecommendItem:RefreshVote()
    local voteNum, isGroupVoted
    if not XTool.IsNumberValid(self.RecommendId) then
        voteNum = 0
        isGroupVoted = true
    else
        local vote = XDataCenter.VoteManager.GetVote(self.RecommendId)
        voteNum = vote.VoteNum
        isGroupVoted = XDataCenter.VoteManager.IsGroupVoted(vote.GroupId)
    end
    self.TxtVoteNum.text = voteNum
    self.BtnVote:SetDisable(isGroupVoted, not isGroupVoted)
end

function XUiEquipRecommendItem:InitCb()
    self.BtnVote.CallBack = function()
        self:OnBtnVoteClick()
    end
    
    self.BtnSet.CallBack = function() 
        self:OnBtnSetClick()
    end
end

function XUiEquipRecommendItem:OnBtnVoteClick()
    XDataCenter.VoteManager.AddVote(self.RecommendId, function()
        if self.AddVoteCb then
            self.AddVoteCb()
        end
    end)
end

function XUiEquipRecommendItem:OnBtnSetClick()
    local putOnPosList = self.Target:CreatePutOnPosList()
    local target = self.Target
    local roleId = target:GetProperty("_CharacterId")
    local targetId = target:GetProperty("_Id")
    
    XDataCenter.EquipGuideManager.EquipGuideSetTargetRequest(
            targetId,
            putOnPosList,
            function()
                if XLuaUiManager.IsUiLoad("UiEquipGuideDetail") then
                    XLuaUiManager.Remove("UiEquipGuideDetail")
                end
                XLuaUiManager.Remove("UiEquipGuideRecommend")
                XLuaUiManager.Open("UiEquipGuideDetail", target)

                
                local progress = target:GetProperty("_Progress")
                local weaponState = target:GetWeaponState()
                local chipsState = target:GetChipsState()
                XDataCenter.EquipGuideManager.RecordSetTargetEvent(roleId, targetId, progress, weaponState, chipsState)
            end
    )
end

function XUiEquipRecommendItem:OnCheckHasStrongerWeapon(count)
    local isShow = count >= 0
    self.BtnSet:ShowTag(isShow)
    if isShow then
        if self.PlayAnimationCb then self.PlayAnimationCb("Panel6StarEnable") end
    end
end



local XUiEquipGuideRecommend = XLuaUiManager.Register(XLuaUi, "UiEquipGuideRecommend")

function XUiEquipGuideRecommend:OnAwake()
    self:InitCb()
    self:InitDynamicTable()
end 

--@type equipGuide XEquipGuide
function XUiEquipGuideRecommend:OnStart(equipGuide, isHideSetTarget)
    self.EquipGuide = equipGuide
    self.IsHideSetTarget = isHideSetTarget
    self:InitView()
end

function XUiEquipGuideRecommend:InitCb()
    self:BindExitBtns()
    self:BindHelpBtn()
    
end 

function XUiEquipGuideRecommend:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskList)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiEquipRecommendItem, handler(self, self.PlayAnimation), handler(self, self.OnAddVote))
    self.PanelDetailEquipItem.gameObject:SetActiveEx(false)
end


function XUiEquipGuideRecommend:InitView()
    
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset
    , XDataCenter.ItemManager.ItemId.FreeGem
    , XDataCenter.ItemManager.ItemId.ActionPoint
    , XDataCenter.ItemManager.ItemId.Coin)
    
    self.TxtName.text = XCharacterConfigs.GetCharacterLogName(self.EquipGuide:GetProperty("_Id"))

    
    if not XDataCenter.VoteManager.IsInit() then
        XDataCenter.VoteManager.GetVoteGroupListRequest(function()
           self:UpdateDynamicTable()
        end)
    else
        self:UpdateDynamicTable()
    end
    
end 

function XUiEquipGuideRecommend:OnAddVote()
    local grids = self.DynamicTable:GetGrids()
    for _, grid in ipairs(grids or {}) do
        grid:RefreshVote()
    end
end

function XUiEquipGuideRecommend:UpdateDynamicTable()
    self.TargetList = self.EquipGuide:GetTargetList()
    self.DynamicTable:SetDataSource(self.TargetList)
    self.DynamicTable:ReloadDataSync()
end

function XUiEquipGuideRecommend:OnDynamicTableEvent(evt, index, grid) 
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.TargetList[index], self.IsHideSetTarget)
    end
end 