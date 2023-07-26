local XAdventureRole = require("XEntity/XBiancaTheatre/Adventure/XAdventureRole")
local XAdventureStep = require("XEntity/XBiancaTheatre/Adventure/XAdventureStep")
local XAdventureChapter = XClass(nil, "XAdventureChapter")

--当前章节数据管理
function XAdventureChapter:Ctor(id)
    self:UpdateChapterId(id)
    -- 步骤
    self.Step = {}
    self.StepDic = {}
    -- 当前招募刷新的次数
    self.RefreshRoleCount = self:GetRefreshRoleMaxCount()
    -- 当前可招募的角色 XAdventureRole
    self.RecruitRoleDic = nil
    -- 等待选择的技能，PS:在选择技能期间重登会拥有部分数据
    self.WaitSelectableSkillIds = nil
    -- 已通关节点数
    self.CurrentPassNodeCount = 0
    -- 是否已准备好
    self.IsReady = false
    -- 完成战斗节点数
    self.PassFightCount = 0
    -- 当前章节是否已通关
    self.PassChapter = 0
end

function XAdventureChapter:UpdateChapterId(chapterId)
    if self.CurrentChapterId == chapterId then
        return
    end
    self.CurrentChapterId = chapterId
    self.Config = XBiancaTheatreConfigs.GetBiancaTheatreChapter(chapterId)
end

function XAdventureChapter:SetIsReady(value)
    self.IsReady = value
end

function XAdventureChapter:GetIsReady()
    return self.IsReady
end

function XAdventureChapter:GetId()
    return self.Config.Id
end

function XAdventureChapter:GetCurrentNodeId()
    local step = self:GetCurStep()
    if not step then
        return
    end
    return step:GetCurrentNodeId()
end

function XAdventureChapter:InitWithServerData(data)
    -- 更新当前步骤数据
    for _, stepData in ipairs(data.Steps) do
        self:AddStep(stepData)
    end

    self.CurrentPassNodeCount = data.PassNodeCount
    self.PassFightCount = data.PassFightCount
    self.PassChapter = data.PassChapter
    self:UpdateRecruitRoleDic()
end

-- 更新已刷新出来的角色
function XAdventureChapter:UpdateRecruitRoleDic()
    local step = self:GetCurStep()
    if not step then
        return
    end
    -- 更新已刷新出来的角色
    self.RecruitRoleDic = {}
    for index, roleId in ipairs(step:GetRefreshCharacterIds()) do
        if roleId > 0 then
            self.RecruitRoleDic[index] = XAdventureRole.New(roleId)
        end
    end
end

--新的步骤
--stepData：XAdventureStep
function XAdventureChapter:AddStep(stepData)
    table.insert(self.Step, XAdventureStep.New(stepData))
    self.StepDic[stepData.Uid] = self.Step[#self.Step]
end

function XAdventureChapter:UpdateWaitSelectableSkillIds(value)
    self.WaitSelectableSkillIds = value
end

function XAdventureChapter:GetWaitSelectableSkillIds()
    return self.WaitSelectableSkillIds
end

function XAdventureChapter:AddPassNodeCount(value)
    self.CurrentPassNodeCount = self.CurrentPassNodeCount + value
end

function XAdventureChapter:GetCurrentPassNodeCount()
    return self.CurrentPassNodeCount
end

-- 更新下一个事件节点
function XAdventureChapter:UpdateNextEventNode(node, newData)
    for _, step in ipairs(self.Step) do
        if not step:IsOverdue() then
            step:UpdateNextEventNode(node, newData)
            return
        end
    end
end

-- 获得一个未完成的步骤
function XAdventureChapter:GetCurStep()
    local step
    for i = #self.Step, 1, -1 do
        step = self.Step[i]
        if not step:IsOverdue() then
            return step
        end
    end
end

-- 根据唯一Id获得步骤
function XAdventureChapter:GetStepByUid(uid)
    return self.StepDic[uid]
end

function XAdventureChapter:GetEventNode(evenId)
    for _, node in ipairs(self:GetCurrentNodes()) do
        if node:GetNodeType() == XBiancaTheatreConfigs.NodeType.Event 
            and node:GetEventId() == evenId then
            return node
        end
    end
end

function XAdventureChapter:GetCurrentNode(step)
    for _, node in ipairs(self:GetCurrentNodes(step)) do
        if node:GetIsSelected() then
            return node
        end
    end
end

function XAdventureChapter:GetIsHasNodeSelected()
    for _, node in ipairs(self:GetCurrentNodes()) do
        if node:GetIsSelected() then
            return true
        end
    end
    return false
end

function XAdventureChapter:GetIsOpen()
    return true
end

function XAdventureChapter:GetOpenIndexIcon()
    return self.Config.OpenIndexIcon
end

function XAdventureChapter:GetOpenTitleIcon()
    return self.Config.OpenTitleIcon
end

function XAdventureChapter:GetOpenBg()
    return self.Config.OpenBg
end

-- 开幕标题
function XAdventureChapter:GetTitle()
    return self.Config.Name
end

function XAdventureChapter:GetCurrentNodes(step)
    local step = step or self:GetCurStep()
    return step and step:GetCurrentNodes() or {}
end

-- 获取招募剩余数量
function XAdventureChapter:GetRecruitCount()
    local step = self:GetCurStep()
    if not step then
        return 0
    end
    return step:GetRecruitCount() - step:GetCurRecruitCount()
end

-- 获取是否能够进入玩法
function XAdventureChapter:GetIsCanEnterGame()
    -- 招满人了，可以进了
    if self:GetRecruitCount() <= 0 then
        return true
    end
    local adventureManager = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager()
    local step = self:GetCurStep()
    -- 是否可以跳过招募直接进入玩法
    local selectTickId = adventureManager:GetSelectTickId()
    if XTool.IsNumberValid(selectTickId) and step then
        local leastRecruitCount = XBiancaTheatreConfigs.GetRecruitTicketLeastRecruitCount(selectTickId)
        if step:GetCurRecruitCount() >= leastRecruitCount then
            return true
        end
    end
    
    local hasRoleRecruit = false
    for _, role in pairs(self:GetRecruitRoleDic()) do
        if adventureManager:GetRole(role:GetId()) == nil then
            hasRoleRecruit = true
            break
        end
    end
    -- 没招满人，但刷新次数为0，或没人可以招了，也可以进了
    if self:GetRefreshRoleCount() <= 0 or not hasRoleRecruit then
        return true
    end
    return false
end

-- 获取招募剩余刷新数量
function XAdventureChapter:GetRefreshRoleCount()
    local step = self:GetCurStep()
    if not step then
        return 0
    end
    return step:GetRefreshCount() - step:GetCurRefreshCount()
end

-- 获得招募刷新最大数量
function XAdventureChapter:GetRefreshRoleMaxCount()
    local step = self:GetCurStep()
    if not step then
        return 0
    end
    return step:GetRefreshCount()
end

-- 获取当前章节可招募的角色
function XAdventureChapter:GetRecruitRoleDic()
    return self.RecruitRoleDic or {}
end

function XAdventureChapter:GetBeginStoryId()
    return self.Config.BeginStory
end

function XAdventureChapter:GetEndStoryId()
    return self.Config.EndStory
end

function XAdventureChapter:GetCurrentChapterId()
    return self.CurrentChapterId
end

function XAdventureChapter:CheckHasMovieNode()
    for _, node in ipairs(self:GetCurrentNodes()) do
        if node:GetNodeType() == XBiancaTheatreConfigs.NodeType.Movie then
            return true
        end
    end
    return false
end

--######################## 协议 begin ########################
-- 请求招募角色
function XAdventureChapter:RequestRecruitRole(id, callback, isDecay)
    -- 检查是否满足招募数次
    if self:GetRecruitCount() <= 0 then
        return 
    end
    local requestBody = {
        CharacterId = id,
    }
    XNetwork.CallWithAutoHandleErrorCode("BiancaTheatreRecruitCharacterRequest", requestBody, function(res)
        XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager():AddRoleById(id, nil, true, isDecay)
        local step = self:GetCurStep()
        if step then
            step:UpdateCurRecruitCount(step:GetCurRecruitCount() + 1)
            step:UpdateRecruitCharacterId(requestBody.CharacterId)
        end
        if callback then callback() end
        XEventManager.DispatchEvent(XEventId.EVENT_THEATRE_RECRUIT_COMPLETE)
        if not isDecay then
            XUiManager.TipText("TheatreRecruitComplete")
        end
    end)
end

-- 请求刷新角色
function XAdventureChapter:RequestRefreshRoles(calllback, showTip)
    if showTip == nil then showTip = true end

    XNetwork.Call("BiancaTheatreRecruitRefreshRequest", nil, function(res)
        if res.Code ~= XCode.Success then
            -- 完全没有招募角色的时候刷新要处理招募次数
            if res.Code == 20176010 then
                -- 数据处理
                local step = self:GetCurStep()
                if step then
                    -- 刷新剩余招募刷新次数
                    step:UpdateCurRefreshCount(step:GetCurRefreshCount() + 1)
                    step:InitRecruitCharacterId()
                end
                -- ui刷新回调
                if calllback then calllback() end
            end
            XUiManager.TipCode(res.Code)
            return
        end

        local step = self:GetCurStep()
        local characterIds = res.CharacterIds
        if step then
            -- 刷新剩余招募刷新次数
            step:UpdateCurRefreshCount(step:GetCurRefreshCount() + 1)
            step:InitRecruitCharacterId()
        end
        
        self.RecruitRoleDic = nil
        self.RecruitRoleDic = {}
        for index, roleId in ipairs(characterIds) do
            if roleId > 0 then
                self.RecruitRoleDic[index] = XAdventureRole.New(roleId)
            end
        end
        
        if calllback then calllback() end
        if showTip then
            XUiManager.TipText("TheatreRecruitRefreshComplete")
        end
    end)
end

--选择节点
function XAdventureChapter:RequestTriggerNode(id, callback)
    local requestBody = {
        NodeId = self:GetCurrentNodeId(),
        SlotId = id
    }
    XNetwork.CallWithAutoHandleErrorCode("BiancaTheatreSelectNodeRequest", requestBody, function(res)
        if callback then callback() end
    end)
end

-- 招募券列表————选择招募券
function XAdventureChapter:RequestSelectRecruitTick(tickId, callback)
    local requestBody = {
        TickId = tickId,    --招募券ID
    }
    XNetwork.CallWithAutoHandleErrorCode("BiancaTheatreSelectRecruitTickRequest", requestBody, function(res)
        if callback then callback(res) end
    end)
end

-- 招募角色-结束招募
function XAdventureChapter:RequestEndRecruit()
    local adventureManager = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager()
    local curStep = adventureManager:GetCurrentChapter():GetCurStep()
    local rootUiStep = self:GetStepByUid(curStep:GetRootUid())
    local stepType = rootUiStep and rootUiStep:GetStepType()

    --上一个步骤（招募中重新登录）或当前步骤（从招募券选择界面进入招募界面）是招募券选择，则显示过渡界面
    local isShowLoading = curStep:GetRootStepType() == XBiancaTheatreConfigs.XStepType.SelectRecruitTicket or
            curStep:GetStepType() == XBiancaTheatreConfigs.XStepType.SelectRecruitTicket
    local isCheckOpen = stepType == XBiancaTheatreConfigs.XStepType.FightReward or 
            stepType == XBiancaTheatreConfigs.XStepType.Node or
            isShowLoading
    curStep:SetOverdue(1)
    XNetwork.Call("BiancaTheatreEndRecruitRequest", nil, function(res)
        if res.Code ~= XCode.Success then
            curStep:SetOverdue(0)
            XUiManager.TipCode(res.Code)
            return
        end
        -- 招募获得道具数据处理
        if not (XTool.IsTableEmpty(res.BiancaTheatreItems)) then
            local itemIdList = {}
            for _, item in ipairs(res.BiancaTheatreItems) do
                table.insert(itemIdList, item.ItemId)
            end
            XDataCenter.BiancaTheatreManager.AddTipOpenData("UiBiancaTheatreTipReward", nil, nil, nil, nil, nil, itemIdList)
        end

        if isCheckOpen then
            XDataCenter.BiancaTheatreManager.CheckOpenView(true, isShowLoading)
        end
    end)
end
--######################## 协议 end ########################

return XAdventureChapter