local TEAM_MEMBER_ORDER = {2, 1, 3} --队伍顺序（蓝，红，黄）

local DEFAULT_SELECT_INDEX = 1 --默认选中辅助机
--==============================
 ---@desc 辅助机预设--辅助机格子
 ---@ui 对应的ui 
 ---@return nil{type}
--==============================
local XUiGridPartner = XClass(nil, "XUiGridPartner")

function XUiGridPartner:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
    
    self:InitUi()
    
end

function XUiGridPartner:InitUi()
    --使用动态列表的点击
    self.BtnClick.gameObject:SetActiveEx(false)
end

--==============================
 ---@desc 刷新显示
 ---@partner @class XPartner
--==============================
function XUiGridPartner:Refresh(partner, carriedDict, idx)
    if not partner then
    
        return
    end
    
    self.RImgHeadIcon:SetRawImage(partner:GetIcon())
    self.RImgQuality:SetRawImage(XMVCA.XCharacter:GetCharacterQualityIcon(partner:GetQuality()))
    self.PanelLv:GetObject("TxtLevel").text = partner:GetLevel()
    self.ImgLock.gameObject:SetActiveEx(partner:GetIsLock())
    self.ImgBreak:SetSprite(partner:GetBreakthroughIcon())

    if idx <= #TEAM_MEMBER_ORDER then
        local id = partner:GetId()
        local pos = carriedDict[id]
        self.ImgIsYellow.gameObject:SetActiveEx(pos == TEAM_MEMBER_ORDER[3])
        self.ImgIsBlue.gameObject:SetActiveEx(pos == TEAM_MEMBER_ORDER[1])
        self.ImgIsRed.gameObject:SetActiveEx(pos == TEAM_MEMBER_ORDER[2])
    end
    
end

function XUiGridPartner:SetSelect(isSelect)
    self.PanelSelected.gameObject:SetActiveEx(isSelect)
end

--=========================================类分界线=========================================--


--==============================
 ---@desc 辅助机预设--队伍角色列表
 ---@ui 对应的ui 
 ---@index 对应的位置
--==============================
local XUiGridRoleTeam = XClass(nil, "XUiGridRoleTeam")

function XUiGridRoleTeam:Ctor(ui, index, selectCb)
    XTool.InitUiObjectByUi(self, ui)
    
    self.Index = index
    self.BtnClick.CallBack = function()
        if not XTool.IsNumberValid(self.RoleId) then 
            XUiManager.TipText("PartnerTeamPrefabNotCharacter")
            return 
        end
        if selectCb then
            selectCb(index)
        end
    end
end

--==============================
 ---@desc 刷新显示
 ---@roleId 角色id 
 ---@partnerId 宠物id, 非TemplateId 
--==============================
function XUiGridRoleTeam:Refresh(roleId, partnerId)
    self.RoleId = roleId
    self.PartnerId = partnerId
    local hasRole = XTool.IsNumberValid(roleId)
    local color = XDataCenter.TeamManager.GetTeamMemberColor(self.Index)
    self.ImgLeftSkill.color = color
    self.ImgRightSkill.color = color
    self.PanelNull.gameObject:SetActiveEx(not hasRole)
    self.PanelHave.gameObject:SetActiveEx(hasRole)
    self.RImgPartnerIcon.gameObject:SetActiveEx(hasRole)
    self.PanelPartnerNone.gameObject:SetActiveEx(not hasRole)

    if hasRole then
        self:SetHave(roleId)
    end
end

function XUiGridRoleTeam:SetHave(roleId)
    if not roleId then
        self.ImgIcon.gameObject:SetActiveEx(false)
        return
    end
    self.ImgIcon.gameObject:SetActiveEx(true)
    local character = XMVCA.XCharacter:GetCharacter(roleId)
    if not character then return end

    self.ImgIcon:SetRawImage(XMVCA.XCharacter:GetCharBigHeadIcon(roleId))
    self.ImgQuality:SetSprite(XMVCA.XCharacter:GetCharacterQualityIcon(character.Quality))

    local hasPartner = XTool.IsNumberValid(self.PartnerId)
    self.RImgPartnerIcon.gameObject:SetActiveEx(hasPartner)
    self.PanelPartnerNone.gameObject:SetActiveEx(not hasPartner)
    if hasPartner then
        local partner = XDataCenter.PartnerManager.GetPartnerEntityById(self.PartnerId)
        self.RImgPartnerIcon:SetRawImage(partner:GetIcon())
    end

end

function XUiGridRoleTeam:SetSelect(isSelect)
    self.ImgSelect.gameObject:SetActiveEx(isSelect)
    if isSelect then
        self.ImgSelect.color = XDataCenter.TeamManager.GetTeamMemberColor(self.Index)
    end
end


--=========================================类分界线=========================================--


--==============================
 ---@desc 辅助机预设
 ---@teamData 预设队伍数据 
--==============================
local XUiPartnerPreset = XLuaUiManager.Register(XLuaUi, "UiPartnerPreset")
local XUiGridPresetSkill = require("XUi/XUiPartner/PartnerPreset/UiPartnerSkill/XUiGridPresetSkill")

function XUiPartnerPreset:OnAwake()
    self:InitUi()
    self:InitCb()
end 

function XUiPartnerPreset:OnStart(teamData, pos)
    self.TeamData = teamData
    self.RoleList = teamData.TeamData
    self.TeamId = teamData.TeamId
    --@class XPartnerPrefab
    self.PartnerPrefab = XDataCenter.TeamManager.GetPartnerPrefab(self.TeamId)
    --刷新当前辅助机技能到缓存中
    self.PartnerPrefab:InitSkillCache(teamData)
    self.RoleGridList = {}
    self.ActiveSkillGrids = {}
    self.PassiveSkillGrids = {}
    --队伍名
    self.TxtName.text = teamData.TeamName
    --角色列表刷新
    self:RefreshRoleList()
    --辅助剂列表刷新
    self:RefreshPartnerList()
    
    --默认选中角色
    local index = pos > 0 and pos or 1
    self:OnSelectRole(index)
   
end

function XUiPartnerPreset:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_PARTNER_PRESET_SKILL_CHANGE, self.OnSkillChange, self)
end

function XUiPartnerPreset:OnDisable()
    XDataCenter.PartnerManager.ClearAllPresetSkillCache()
    XEventManager.RemoveEventListener(XEventId.EVENT_PARTNER_PRESET_SKILL_CHANGE, self.OnSkillChange, self)
end

--region 回调

--==============================
 ---@desc 选择角色回调
 ---@index 位置 
--==============================
function XUiPartnerPreset:OnSelectRole(index)
    if index == self.SelectRoleIndex then return end

    --人物切换之前判断
    self:CheckIsClearSkillCache()
    
    self.SelectRoleIndex = index
    for i, grid in ipairs(self.RoleGridList) do
        grid:SetSelect(i == index)
    end

    local partner = self.PartnerList[self.SelectPartnerIndex]
    self:CheckIsUpdateSkillData(partner, function()
        self:RefreshProperty(partner)
    end)
end

--==============================
 ---@desc 选择辅助机回调
 ---@idx 辅助机下标 
--==============================
function XUiPartnerPreset:OnClickPartner(idx)
    if idx == self.SelectPartnerIndex then return end

    --辅助机切换之前判断
    self:CheckIsClearSkillCache()
    
    self.SelectPartnerIndex = idx
    local grids = self.DynamicTable:GetGrids()
    for i, grid in ipairs(grids) do
        grid:SetSelect(i == idx)
    end

    local partner = self.PartnerList[idx]
    self:PlayAnimation("RightQieHuan", nil, function()
        self:RefreshProperty(partner)
    end)
end

function XUiPartnerPreset:OnDynamicTableEvent(evt, idx, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.PartnerList[idx], self.CarriedDict, idx)
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:OnClickPartner(idx)
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        --默认选中辅助机
        local hasPartner = self:CheckHasPartner()
        local targetIndex
        if hasPartner then
            targetIndex = self:GetEquipPartnerIndexBySelectRole()
        else
            targetIndex = self:GetFirstNoEquipIndex()
        end
        self:OnClickPartner(targetIndex)
    end
end

--==============================
 ---@desc 检测是否需要清除技能缓存
--==============================
function XUiPartnerPreset:CheckIsClearSkillCache()
    if not XTool.IsNumberValid(self.SelectPartnerIndex) then
        return
    end
    
    local lastPartner = self.PartnerList[self.SelectPartnerIndex]
    local partnerId = lastPartner:GetId()
    local changeSkill = self.PartnerPrefab:IsSkillChangeWithPrefab2Cache(partnerId)

    if changeSkill then
        XDataCenter.PartnerManager.ClearPresetSkillCache(partnerId)
        local msg = XUiHelper.GetText("PartnerTeamPrefabSkillNotSaveTips", lastPartner:GetName())
        XUiManager.TipMsg(msg)
        local isCarried = XTool.IsNumberValid(self.CarriedDict[partnerId])
        if isCarried then
            local pos = self.PartnerPrefab:GetPosByPartnerId(partnerId)
            self.PartnerPrefab:UpdateSkillData(pos, partnerId)
        end
    end
end

--==============================
 ---@desc 检测是否需要更新技能数据到辅助机预设中
 ---@partner @class XPartner 
 ---@cancelCb 不更新回调 
--==============================
function XUiPartnerPreset:CheckIsUpdateSkillData(partner, cancelCb)
    if not partner then
        return
    end
    
    local id = partner:GetId()
    local isCarried = XTool.IsNumberValid(self.CarriedDict[id])
    local isCorresponding = self:GetEquipPartnerIndexBySelectRole() == self.SelectPartnerIndex
    local changeSkill = self.PartnerPrefab:IsSkillChangeWithPrefab2Cache(id)

    if changeSkill and isCarried and isCorresponding then
        local beginCb = function()
            self.PartnerPrefab:UpdateSkillData(self.SelectRoleIndex, id)
            local skillData = self.PartnerPrefab:GetSkillData(id)
            XDataCenter.PartnerManager.TeamPreSetPartnerRequest(self.TeamId, self.SelectRoleIndex, id, skillData, function()
                self:RefreshProperty(partner)
                XEventManager.DispatchEvent(XEventId.EVENT_TEAM_PREFAB_CHANGE, self.TeamId, self.TeamData)
            end)
        end
        self:OpenPopupTip(XUiHelper.GetText("PartnerTeamPrefabSkillSaveTips"), beginCb)
    else
        if cancelCb then cancelCb() end
    end
end

--==============================
 ---@desc 修改技能回调
 ---@partner @class partner 
--==============================
function XUiPartnerPreset:OnSkillChange(partner)
    if not partner then
        return
    end
    
    self:CheckIsUpdateSkillData(partner, function()
        self:RefreshProperty(partner)
    end)
end

--携带
function XUiPartnerPreset:OnBtnTakeOnClick()
    self:OpenPopupTip(XUiHelper.GetText("PartnerTeamPrefabEquipTips"), function()
        self:Equip()
    end)
    
end

--卸下
function XUiPartnerPreset:OnBtnTakeOffClick()
    self:OpenPopupTip(XUiHelper.GetText("PartnerTeamPrefabUnloadTips"), function()
        self:Unload()
    end)
end

--更换
function XUiPartnerPreset:OnBtnTakeChangeClick()
    self:OpenPopupTip(XUiHelper.GetText("PartnerTeamPrefabExchangeTips"), function()
        self:Equip()
    end)
    
end

--endregion

--region 初始化
function XUiPartnerPreset:InitUi()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelPartnerScroll)
    self.DynamicTable:SetProxy(XUiGridPartner)
    self.DynamicTable:SetDelegate(self)
    self.GridPartner.gameObject:SetActiveEx(false)
    self.GridSkill.gameObject:SetActiveEx(false)
end

function XUiPartnerPreset:InitCb()
    self:BindHelpBtn(self.BtnHelp, "PartnerPrefabHelp")
    self.BtnBack.CallBack = function() 
        self:CheckIsClearSkillCache()
        self:Close()
    end
    self.BtnMainUi.CallBack = function()
        self:CheckIsClearSkillCache()
        XLuaUiManager.RunMain()
    end
    self.BtnTakeOn.CallBack = function() 
        self:OnBtnTakeOnClick()
    end
    self.BtnTakeChange.CallBack = function() 
        self:OnBtnTakeChangeClick()
    end
    self.BtnTakeOff.CallBack = function() 
        self:OnBtnTakeOffClick()
    end
end

--==============================
 ---@desc 刷新角色列表
--==============================
function XUiPartnerPreset:RefreshRoleList()

    for i, order in ipairs(TEAM_MEMBER_ORDER) do
        local grid = self.RoleGridList[order]
        local roleId = self.RoleList[order]
        local partnerId = self.PartnerPrefab:GetPartnerIdByPos(order)
        if not grid then
            local ui = i == 1 and self.GridTeamRole or CS.UnityEngine.Object.Instantiate(self.GridTeamRole, self.PanelTeam, false)
            ui.gameObject.name = string.format("GridTeamRole%d", order)
            grid = XUiGridRoleTeam.New(ui, order, handler(self, self.OnSelectRole))
            self.RoleGridList[order] = grid
        end
        grid:Refresh(roleId, partnerId)
    end
end

--==============================
 ---@desc 刷新辅助剂列表
--==============================
function XUiPartnerPreset:RefreshPartnerList()
    self.DynamicTable:Clear()
    self.PartnerList = XDataCenter.PartnerManager.GetPartnerOverviewDataList()
    self.CarriedDict = self.PartnerPrefab:GetCarriedDict()
    XPartnerSort.PresetSort(self.PartnerList, self.CarriedDict)
    self.DynamicTable:SetDataSource(self.PartnerList)
    self.DynamicTable:ReloadDataASync(1)
    self:PlayAnimation("LeftQieHuan")
end

--==============================
 ---@desc 刷新辅助机属性
 ---@partner 辅助机实体 @class XPartner
--==============================
function XUiPartnerPreset:RefreshProperty(partner)
    if not partner then
        return
    end
    local partnerId = partner:GetId()
    
    self.RImgPartnerIcon:SetRawImage(partner:GetIcon())
    self.RawImageQuality:SetRawImage(XMVCA.XCharacter:GetCharacterQualityIcon(partner:GetQuality()))
    self.TxtPartnerName.text = partner:GetName()
    self.TxtPartnerLevel.text = partner:GetLevel()
    self.TxtSelectAbil.text = partner:GetAbility()

    --region 刷新按钮状态

    --当前角色是否携带辅助机
    local hasPartner = self:CheckHasPartner()
    self.BtnTakeOn.gameObject:SetActiveEx(not hasPartner)
    --角色位置与辅助机一一对应
    local isCorresponding = self:GetEquipPartnerIndexBySelectRole() == self.SelectPartnerIndex
    self.BtnTakeOff.gameObject:SetActiveEx(hasPartner and isCorresponding)
    self.BtnTakeChange.gameObject:SetActiveEx(hasPartner and not isCorresponding)
    
    --endregion
    
    --region 刷新技能列表
    --携带的主动技能
    local activeSkills  = XDataCenter.PartnerManager.GetPresetSkillList(partnerId, XPartnerConfigs.SkillType.MainSkill)
    --携带的被动技能
    local passiveSkills = XDataCenter.PartnerManager.GetPresetSkillList(partnerId, XPartnerConfigs.SkillType.PassiveSkill)
    
    local skillCount = partner:GetQualitySkillColumnCount()
    for idx = 1, XPartnerConfigs.MainSkillCount do
        local grid = self.ActiveSkillGrids[idx]
        if not grid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridSkill, self.PanelSkills, false)
            ui.gameObject:SetActiveEx(true)
            grid = XUiGridPresetSkill.New(ui)
            grid.GameObject.name = string.format("ActiveSkill%d", idx)
            self.ActiveSkillGrids[idx] = grid
        end
        grid:Refresh(activeSkills[idx], partner, false, XPartnerConfigs.SkillType.MainSkill, idx + 1, self.PartnerPrefab)
    end

    for idx = 1, XPartnerConfigs.PassiveSkillCount do
        local grid = self.PassiveSkillGrids[idx]
        if not grid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridSkill, self.PanelSkills, false)
            ui.gameObject:SetActiveEx(true)
            grid = XUiGridPresetSkill.New(ui)
            grid.GameObject.name = string.format("PassiveSkill%d", idx)
            self.PassiveSkillGrids[idx] = grid
        end
        grid:Refresh(passiveSkills[idx], partner, skillCount < idx, XPartnerConfigs.SkillType.PassiveSkill, idx + 1, self.PartnerPrefab)
    end
    --endregion
end

--endregion

--==============================
 ---@desc 判断当前角色是否携带辅助机
 ---@return boolean
--==============================
function XUiPartnerPreset:CheckHasPartner()
    local index = self.SelectRoleIndex
    local partnerId = self.PartnerPrefab:GetPartnerIdByPos(index)
    
    return XTool.IsNumberValid(partnerId)
end 

--==============================
 ---@desc 获取未被装备的辅助机的第一个，可能没有，没有则选中第一个
 ---@return number
--==============================
function XUiPartnerPreset:GetFirstNoEquipIndex()
    local partnerCount = #self.PartnerList
    if partnerCount <= 0 then
        return 0
    end
    --携带了几个辅助机
    local carryCount = self.PartnerPrefab:GetCarriedCount()
   
    if partnerCount > carryCount then
        return carryCount + 1
    else
        return DEFAULT_SELECT_INDEX
    end
end

--==============================
 ---@desc 根据选中角色获取已经装备的辅助机下标
 ---@return number
--==============================
function XUiPartnerPreset:GetEquipPartnerIndexBySelectRole()
    local partnerCount = #self.PartnerList
    if partnerCount <= 0 then
        return 0
    end

    local partnerId = self.PartnerPrefab:GetPartnerIdByPos(self.SelectRoleIndex)
    if not XTool.IsNumberValid(partnerId) then return 0 end
    --最多只检查前三位，队伍容量为3
    local maxIndex = #self.RoleList
    for i, partner in ipairs(self.PartnerList) do
        if i > maxIndex then return DEFAULT_SELECT_INDEX end
        if partner:GetId() == partnerId then
            return i
        end
    end
    return DEFAULT_SELECT_INDEX
end

--==============================
 ---@desc 左上角提示
 ---@title 提示内容
--==============================
function XUiPartnerPreset:OpenPopupTip(title, beginCb, endCb)
    title = title or ""
    --避免同时打开多个界面
    XLuaUiManager.SetMask(true)
    if beginCb then beginCb() end
    XLuaUiManager.Open("UiPartnerPopupTip", title, function()
        if endCb then endCb() end
        XLuaUiManager.SetMask(false)
    end)
end 

--==============================
 ---@desc 携带/替换
--==============================
function XUiPartnerPreset:Equip()
    local partner = self.PartnerList[self.SelectPartnerIndex]
    local partnerId = partner:GetId()
    
    local equipFunc = function()
        self.PartnerPrefab:Equip(self.SelectRoleIndex, partnerId)
        local skillData = self.PartnerPrefab:GetSkillData(partnerId)
        XDataCenter.PartnerManager.TeamPreSetPartnerRequest(self.TeamId, self.SelectRoleIndex, partnerId, skillData, function()
            self.SelectPartnerIndex = 0
            self:RefreshPartnerList()
            self:RefreshRoleList()

            XEventManager.DispatchEvent(XEventId.EVENT_TEAM_PREFAB_CHANGE, self.TeamId, self.TeamData)
        end)
    end
    
    local unloadThenEquipFunc = function()
        local pos = self.PartnerPrefab:GetPosByPartnerId(partnerId)
        self.PartnerPrefab:Unload(pos, true)
        XDataCenter.PartnerManager.TeamPreSetPartnerRequest(self.TeamId, pos, 0, {}, function()
            equipFunc()
        end)
    end
    
    --当前角色是否携带辅助机
    local isRoleEquipPartner = self:CheckHasPartner()
    --选择辅助机是否被携带
    local isPartnerEquipped = self.PartnerPrefab:GetIsCarry(partnerId)
    if isRoleEquipPartner then
        if isPartnerEquipped then
            --当前角色携带辅助机，选中辅助机已经携带 ---> 先从自身卸下清缓存，再从原先携带者卸下不清缓存，再携带
            self.PartnerPrefab:Unload(self.SelectRoleIndex)
            unloadThenEquipFunc()
        else
            --当前角色携带辅助机，选中辅助机未被携带 ---> 先从自身卸下清缓存，再携带
            self.PartnerPrefab:Unload(self.SelectRoleIndex)
            equipFunc()
        end
    else
        if isPartnerEquipped then
            --当前角色未携带辅助机，选中辅助机已经携带 ---> 先从原先携带者卸下不清缓存，再携带
            unloadThenEquipFunc()
        else
            --当前角色未携带辅助机，选中辅助机未被携带 ---> 直接装备
            equipFunc()
        end
    end

end 

--==============================
 ---@desc 卸下
--==============================
function XUiPartnerPreset:Unload()

    if not XTool.IsNumberValid(self.SelectRoleIndex) then return end
    
    self.PartnerPrefab:Unload(self.SelectRoleIndex)

    XDataCenter.PartnerManager.TeamPreSetPartnerRequest(self.TeamId, self.SelectRoleIndex, 0, {}, function()
        self.SelectPartnerIndex = 0
        self:RefreshPartnerList()
        self:RefreshRoleList()
        
        XEventManager.DispatchEvent(XEventId.EVENT_TEAM_PREFAB_CHANGE, self.TeamId, self.TeamData)
    end)
end