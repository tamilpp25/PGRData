local XUiPanelArea = require("XUi/XUiMission/XUiPanelArea")

local CsVector3 = CS.UnityEngine.Vector3
local CsQuaternion = CS.UnityEngine.Quaternion
local NormalPivot = CS.UnityEngine.Vector2(0.5, 0.5)
local CsDistance = CsVector3.Distance
local CsInOutQuart = CS.DG.Tweening.Ease.InOutQuart

---@class XUiPanelAreaWarMainBlockList3D
---@field Parent XUiAreaWarMain
---@field Line UnityEngine.RectTransform
---@field PanelLine UnityEngine.RectTransform
---@field PanelStage UnityEngine.RectTransform
---@field GridBlocks table<number,XUiGridAreaWarBlock>
---@field GridQuests table<number,XUiGridAreaWarQuest>
---@field BlockScript table<number, XAreaWarBlockArea>
---@field GameObject UnityEngine.GameObject
local XUiPanelAreaWarMainBlockList3D = XClass(nil, "XUiPanelAreaWarMainBlockList3D")
local XUiGridAreaWarBlock = require("XUi/XUiAreaWar/XUiGridAreaWarBlock")
local XUiGridAreaWarQuest = require("XUi/XUiAreaWar/XUiGridAreaWarQuest")


function XUiPanelAreaWarMainBlockList3D:Ctor(ui, parent)
    XTool.InitUiObjectByUi(self, ui)
    self.Parent = parent
    self.FirstRefresh = true
    self.LinePivot = self.Line.pivot
    self.GridBlocks = {}
    self.GridQuests = {}
    self.GridLines = {}
    self.LineSize = self.Line.sizeDelta
    self.ClickBlockCb = handler(self, self.OnClickBlock)
    self.ClickQuestCb = handler(self, self.OnClickQuest)
    self.IsNormaCameraCb = handler(self.Parent, self.Parent.IsNormalCamera)
    --用于计算的Vector3 避免重复创建对象
    self.CalVec3 = CsVector3.zero
    --相机引用
    self.NormalVirtual = self.Parent.VirtualCameraMap.Normal.Camera
    self.DetailVirtual = self.Parent.VirtualCameraMap.StageDetail.Camera

    self.IsSmall = false
    
    self._OnCameraUpdateCb = function() 
        self:DoCameraUpdate()
    end
    
    CS.XAreaWarManager.Instance:AddOnCameraUpdate(self._OnCameraUpdateCb)
    self:InitAngle()
end

function XUiPanelAreaWarMainBlockList3D:OnDispose()
    CS.XAreaWarManager.Instance:RemoveOnCameraUpdate(self._OnCameraUpdateCb)
    XDataCenter.AreaWarManager.SaveLastCameraFollowPointPos(self.CameraFollowPoint.transform.position)
end

function XUiPanelAreaWarMainBlockList3D:DoCameraUpdate()
    if XTool.UObjIsNil(self.GameObject) then
        return
    end

    if not self.GameObject.activeInHierarchy then
        return
    end

    local isNormal = self.Parent:IsNormalCamera()
    self:OnUpdateVisible(self.GridBlocks, isNormal, self.FocusDetailBlockId)
    self:OnUpdateVisible(self.GridQuests, isNormal, self.FocusDetailQuestId)
end

function XUiPanelAreaWarMainBlockList3D:OnUpdateVisible(grids, isNormal, targetFocusId)
    if XTool.IsTableEmpty(grids) then
        return
    end
    for id, grid in pairs(grids) do
        local visible
        if isNormal then
            visible = CS.XAreaWarManager.Instance:IsInView(grid.Transform, -0.2, 1.2, -0.5, 1.2)
            if visible then
                if self.IsSmall then
                    grid:PlayMiniEnable()
                else
                    grid:PlayMiniDisable()
                end
            end
        else
            visible = id == targetFocusId
        end
        grid:SetVisible(visible)
        CS.XAreaWarManager.Instance:WorldPoint2CanvasPoint(grid:GetBindParam(), grid.Transform)
    end
end

function XUiPanelAreaWarMainBlockList3D:Refresh(isRepeatChallenge)
    self.IsRepeatChallenge = isRepeatChallenge
    for _, chapterId in pairs(XAreaWarConfigs.GetChapterIds()) do
        --章节开放
        local blockIds = XAreaWarConfigs.GetBlockIdsByChapterId(chapterId)
        for _ ,blockId in pairs(blockIds) do
            if XDataCenter.AreaWarManager.IsBlockVisible(blockId) then
                self:UpdateBlock(blockId)
            end
        end
    end

    self:UpdateDailyQuest()
    self:UpdateRescueQuest()
    
    --首次刷新
    if self.FirstRefresh then
        --还原上次相机位置
        local pos = XDataCenter.AreaWarManager.GetLastCameraFollowPointPos()
        if not pos then
            local allBockIds = XAreaWarConfigs.GetAllBlockIds()
            pos = self:_GetGridParent(allBockIds[1]).transform.position
        end
        self.CameraFollowPoint.transform.position = pos

        self.FirstRefresh = false

        self:DoCameraUpdate()
    end
end

function XUiPanelAreaWarMainBlockList3D:UpdateDailyQuest()
    local personal = XDataCenter.AreaWarManager.GetPersonal()
    local questList = personal:GetDailyQuestList(false)
    for index, questId in ipairs(questList) do
        self:UpdateQuest(personal:GetLocalDailyIndex(questId, index) or index, questId, true)
    end
    personal:SetLocalDailyRandomDict()
end

function XUiPanelAreaWarMainBlockList3D:UpdateRescueQuest()
    local personal = XDataCenter.AreaWarManager.GetPersonal()
    local questList = personal:GetRescueQuestList(false)
    for index, questId in ipairs(questList) do
        self:UpdateQuest(personal:GetLocalRescueIndex(questId, index), questId, false)
    end
    personal:SetLocalRescueRandomDict()
end

function XUiPanelAreaWarMainBlockList3D:RefreshNewUnlockBlocks()
    local checkMap = XDataCenter.AreaWarManager.GetNewUnlockBlockIdDic()
    for blockId in pairs(checkMap) do
        self:UpdateBlock(blockId)
    end
    
    XDataCenter.AreaWarManager.SetNewUnlockBlockIdDicCookie(checkMap)
end

function XUiPanelAreaWarMainBlockList3D:UpdateQuest(index, questId, isDaily)
    local grid = self.GridQuests[questId]
    if not grid then
        grid = self:CreateQuestPanel(index, questId, isDaily)
    end
    if grid then
        grid:Refresh(questId)
    end
end

function XUiPanelAreaWarMainBlockList3D:UpdateBlock(blockId)

    local grid = self.GridBlocks[blockId]
    if not grid then
        grid = self:CreateBlockPanel(blockId)
        local preBlockIds = XAreaWarConfigs.GetAllPreBlockIds(blockId)
        for _, preBlockId in pairs(preBlockIds) do
            if XDataCenter.AreaWarManager.IsBlockVisible(preBlockId) then
                self:CreateArrowLine(preBlockId, blockId)
            end
        end
    end
    
    grid:Refresh(blockId, self.IsRepeatChallenge)
end

function XUiPanelAreaWarMainBlockList3D:FocusTargetBlock(blockId)
    local grid = self.GridBlocks[blockId]
    if not grid then
        XLog.Error(
                "XUiPanelAreaWarMainBlockList3D:FocusTargetBlock error: grid not exist, blockId: ",
                blockId
        )
        return
    end
    self:DoFocusBlock(grid)
    self.FocusDetailBlockId = nil
end

function XUiPanelAreaWarMainBlockList3D:FocusBlockDetail(blockId)
    local grid = self.GridBlocks[blockId]
    if not grid then
        XLog.Error(
                "XUiPanelAreaWarMainBlockList3D:FocusBlockDetail error: grid not exist, blockId: ",
                blockId
        )
        return
    end
    self:DoFocusDetail(grid)
    
    for id, tempGrid in pairs(self.GridBlocks) do
        tempGrid:SetVisible(id == blockId)
    end

    for _, tempGrid in pairs(self.GridQuests) do
        tempGrid:SetVisible(false)
    end
    
    self.FocusDetailBlockId = blockId
end

function XUiPanelAreaWarMainBlockList3D:FocusTargetQuest(questId)
    local grid = self.GridQuests[questId]
    if not grid then
        return
    end
    self:DoFocusBlock(grid)
    self.FocusDetailQuestId = nil
end

function XUiPanelAreaWarMainBlockList3D:FocusQuestDetail(questId)
    local grid = self.GridQuests[questId]
    if not grid then
        XLog.Error(
                "XUiPanelAreaWarMainBlockList3D:FocusQuestDetail error: grid not exist, questId: ",
                questId
        )
        return
    end
    self:DoFocusDetail(grid)
    
    for _, tempGrid in pairs(self.GridBlocks) do
        tempGrid:SetVisible(false)
    end
    
    for id, tempGrid in pairs(self.GridQuests) do
        tempGrid:SetVisible(id == questId)
    end
    self.FocusDetailQuestId = questId
end

function XUiPanelAreaWarMainBlockList3D:DoFocusDetail(grid)
    if not grid then
        return
    end
    
    for _, camera in pairs(self.DetailVirtual) do
        camera.Follow = grid.Transform.parent
    end

    self:RefreshLineState(false)
    if self.IsSmall then
        grid:PlayMiniDisable()
    end
    grid:PlayNearAnim()
end

function XUiPanelAreaWarMainBlockList3D:DoFocusBlock(grid)
    if not grid then
        return
    end
    grid:TryPlayLocation()
    self:DoMoveFollow(grid.Transform.position)

    for _, camera in pairs(self.NormalVirtual) do
        camera.Follow = self.CameraFollowPoint.transform
    end

    self:RefreshLineState(true)

    for _, tempGrid in pairs(self.GridBlocks) do
        tempGrid:SetVisible(true)
    end

    for _, tempGrid in pairs(self.GridQuests) do
        tempGrid:SetVisible(true)
    end
end

function XUiPanelAreaWarMainBlockList3D:PlayGridFarAnim(blockId)
    local grid = self.GridBlocks[blockId]
    if not grid then
        XLog.Error("XUiPanelAreaWarMainBlockList3D:PlayGridFarAnim error: grid not exist, blockId: ", blockId)
        return
    end

    grid:PlayFarAnim()
    
    if self.IsSmall then
        grid:PlayMiniEnable()
    end
end

function XUiPanelAreaWarMainBlockList3D:PlayQuestFarAnim(questId)
    local grid = self.GridQuests[questId]
    if not grid then
        return
    end

    grid:PlayFarAnim()

    if self.IsSmall then
        grid:PlayMiniEnable()
    end
end

--动态创建线
function XUiPanelAreaWarMainBlockList3D:CreateArrowLine(startBlockId, endBlockId)
    if not XTool.IsNumberValid(startBlockId) or not XTool.IsNumberValid(endBlockId) then
        return
    end
    
    local key = self:_GetLineKey(startBlockId, endBlockId)
    if self.GridLines[key] then
        return
    end
    
    local name = self:_GetLineName(startBlockId, endBlockId)
    ---@type UnityEngine.GameObject
    local obj = self.PanelLine:FindTransform(name)
    if obj then
        self.GridLines[self:_GetLineKey(startBlockId, endBlockId)] = obj
        return
    end
    ---@type UnityEngine.GameObject
    obj = XUiHelper.Instantiate(self.Line, self.PanelLine)
    obj.name = name

   self:SetLineTransform(obj, startBlockId, endBlockId)
    obj.gameObject:SetActiveEx(true)
    self.GridLines[key] = obj
end

function XUiPanelAreaWarMainBlockList3D:ResetLinePosition()
    for key, grid in pairs(self.GridLines) do
        local startBlockId, endBlockId = self:_GetLineStartAndEndBlockId(key)
        self:SetLineTransform(grid, startBlockId, endBlockId)
    end
end

function XUiPanelAreaWarMainBlockList3D:SetLineTransform(obj, startBlockId, endBlockId)
    local position, angle, distance = self:CalculateLineWith3DUI(self:_GetGridLinePoint(startBlockId), self:_GetGridLinePoint(endBlockId), self.LinePivot)
    obj.transform.localPosition = position
    obj.transform.localRotation = angle
    local size = self.LineSize
    size.x = distance
    obj.transform.sizeDelta = size
end

--- 动态创建探索任务节点
---@param 
---@return
--------------------------
function XUiPanelAreaWarMainBlockList3D:CreateQuestPanel(index, questId, isDaily)
    local questType = isDaily and 1 or 2
    local name = string.format("Quest_%d_%d", questType, index)
    local quest = XUiHelper.Instantiate(self.Stage, self.PanelStage)
    quest.name = name
    quest.gameObject:SetActiveEx(true)

    local prefabPath = XAreaWarConfigs.GetQuestShowTypePrefab(questId)
    local go = quest.transform:LoadPrefab(prefabPath)
    local t3DTransform = self.Parent:TryGetQuestTransform(isDaily, index - 1)
    if XTool.UObjIsNil(t3DTransform) then
        return
    end
    local grid = XUiGridAreaWarQuest.New(go, t3DTransform, self.ClickQuestCb)
    local instance = CS.XAreaWarManager.Instance
    instance:WorldPoint2CanvasPoint(t3DTransform, quest.transform)
    
    self.GridQuests[questId] = grid
    
    return grid
end

function XUiPanelAreaWarMainBlockList3D:RemoveQuest(questId)
    local quest = self.GridQuests[questId]
    if not quest then
        return
    end
    quest:TryRemove()

    self.GridQuests[questId] = nil
end

function XUiPanelAreaWarMainBlockList3D:IsQuestTransform(questId, transform)
    if XTool.UObjIsNil(transform) then
        return false
    end
    local quest = self.GridQuests[questId]
    if not quest then
        return false
    end
    
    return quest:IsSameTransform(transform)
end

--- 动态创建关卡节点
---@param blockId number
---@return XUiGridAreaWarBlock
--------------------------
function XUiPanelAreaWarMainBlockList3D:CreateBlockPanel(blockId)
    local name = string.format("Block_%d", blockId)
    local block = XUiHelper.Instantiate(self.Stage, self.PanelStage)
    block.name = name
    block.gameObject:SetActiveEx(true)
    
    local prefabPath = XAreaWarConfigs.GetBlockShowTypePrefab(blockId)
    local go = block.transform:LoadPrefab(prefabPath)
    local grid = XUiGridAreaWarBlock.New(go, self.ClickBlockCb)
 
    local instance = CS.XAreaWarManager.Instance

    instance:WorldPoint2CanvasPoint(blockId, block.transform)
    local rotationY = instance:GetBlockRotateY(blockId)
    self:SetCalVec3(0, 0, rotationY)
    grid:Rotate(CS.UnityEngine.Quaternion.Euler(self.CalVec3))
    self.GridBlocks[blockId] = grid
    
    return grid
end

function XUiPanelAreaWarMainBlockList3D:PlayScaleAnim(isSmall)
    if self.IsSmall == isSmall then
        return
    end
    self.IsSmall = isSmall
    for _, grid in pairs(self.GridBlocks) do
        if self.IsSmall then
            grid:PlayMiniEnable()
        else
            grid:PlayMiniDisable()
        end
    end
    
    for _, grid in pairs(self.GridQuests) do
        if self.IsSmall then
            grid:PlayMiniEnable()
        else
            grid:PlayMiniDisable()
        end
    end
end

function XUiPanelAreaWarMainBlockList3D:RefreshLineState(state)
    self.PanelLine.gameObject:SetActiveEx(state)
end

function XUiPanelAreaWarMainBlockList3D:RefreshStageState(state)
    self.PanelStage.gameObject:SetActiveEx(state)
end

function XUiPanelAreaWarMainBlockList3D:OnClickBlock(blockId)
    if not XDataCenter.AreaWarManager.IsBlockUnlock(blockId) then
        --优先提示区块解锁时间
        if XDataCenter.AreaWarManager.GetBlockUnlockLeftTime(blockId) > 0 then
            local openTime = XDataCenter.AreaWarManager.GetBlockUnlockTime(blockId)
            local tipStr =
            CsXTextManagerGetText(
                    "AreaWarBlockUnlockTime",
                    XTime.TimestampToGameDateTimeString(openTime, "MM/dd  HH:mm")
            )
            XUiManager.TipMsg(tipStr)
            return
        end

        --提示未解锁区块
        local needTip, tipStr = XDataCenter.AreaWarManager.GetBlockUnlockTips(blockId)
        XUiManager.TipMsg(tipStr)
        return
    end
    self.Parent:OnClickBlock(blockId)
end

function XUiPanelAreaWarMainBlockList3D:OnClickQuest(questId)
    self.Parent:OnClickQuest(questId)
end

function XUiPanelAreaWarMainBlockList3D:SetAsBlockChild(transform, blockId)
    local grid = self:_GetGridParent(blockId)
    if not grid then
        XLog.Error("XUiPanelAreaWarMainBlockList3D:SetAsBlockChild error: grid not exist, blockId: ", blockId)
        return
    end
    transform:SetParent(grid.transform, false)
end

function XUiPanelAreaWarMainBlockList3D:GetBlockWorldPoint(blockId)
    local grid = self:_GetGridParent(blockId)
    if not grid then
        XLog.Error("XUiPanelAreaWarMainBlockList3D:GetBlockWorldPoint error: grid not exist, blockId: ", blockId)
        return CsVector3.zero
    end
    return grid.transform.position
end

---@return UnityEngine.Vector3
function XUiPanelAreaWarMainBlockList3D:_GetGridLinePoint(blockId)
    local grid = self.GridBlocks[blockId]
    if not grid or XTool.UObjIsNil(grid.GameObject) then
        return CsVector3.zero
    end
    return grid:GetLinePoint()
end

function XUiPanelAreaWarMainBlockList3D:_GetLineKey(startBlockId, endBlockId)
    return startBlockId * 1000 + endBlockId
end

function XUiPanelAreaWarMainBlockList3D:_GetLineStartAndEndBlockId(key)
    local endBlockId = key % 1000
    local startBlockId = math.floor(key / 1000)
    
    return startBlockId, endBlockId
end

function XUiPanelAreaWarMainBlockList3D:_GetLineName(startBlockId, endBlockId)
    return string.format("Line_%d_To_%d", startBlockId, endBlockId)
end

function XUiPanelAreaWarMainBlockList3D:_GetGridParent(blockId)
    local grid = self.GridBlocks[blockId]
    if not grid then
        return
    end
    return grid.Transform.parent
end

--- 根据起始点，结束点计算线的长度，位置，旋转信息
---@param startPoint UnityEngine.Vector3
---@param endPoint UnityEngine.Vector3
---@param pivot UnityEngine.Vector2
---@return UnityEngine.Vector3, UnityEngine.Quaternion, number
--------------------------
function XUiPanelAreaWarMainBlockList3D:CalculateLineWith3DUI(startPoint, endPoint, pivot)
    pivot = pivot or NormalPivot
    local offset = endPoint - startPoint
    local width = offset.magnitude
    --local height = endPoint.y - startPoint.y
    local position = (startPoint + endPoint) / 2
    position.x = position.x + (0.5 - pivot.x) * width
    position.y = position.y + (0.5 - pivot.y)
    
    self:SetCalVec3(offset.x, offset.y, 0)
    local angleZ = CsVector3.Angle(CsVector3.right, self.CalVec3)
    self:SetCalVec3(offset.x, 0, offset.z)
    local angleY = CsVector3.Angle(CsVector3.left, self.CalVec3)
    
    
    local xNum, yNum, zNum = offset.x >= 0 and 1 or 0, offset.y >= 0 and 1 or 0, offset.z >= 0 and 1 or 0
    local key = xNum * 256 + yNum * 16 + zNum * 1
    local fun = self.AngleFunc[key]
    if not key then
        XLog.Error("no transform function for " .. xNum, yNum, zNum)
        self:SetCalVec3(0, angleY, angleZ)
        return position, CsQuaternion.Euler(self.CalVec3), width
    end
    angleY, angleZ = fun(angleY, angleZ)
    self:SetCalVec3(0, angleY, angleZ)
    return position, CsQuaternion.Euler(self.CalVec3), width
end

function XUiPanelAreaWarMainBlockList3D:SetCalVec3(x, y, z)
    self.CalVec3.x = x
    self.CalVec3.y = y
    self.CalVec3.z = z
end

function XUiPanelAreaWarMainBlockList3D:InitAngle()
    self.AngleFunc = {
        [0x011] = function(x, y) return x, y end,
        [0x110] = function(x, y) return -x, 180-y end,
        [0x001] = function(x, y) return x, -y end,
        [0x010] = function(x, y) return -x, y end,
        [0x111] = function(x, y) return x, 180-y end,
        [0x100] = function(x, y) return -x, y+180 end,
        [0x101] = function(x, y) return x, y+180 end,
        [0x000] = function(x, y) return -x, -y end,
    }
end

function XUiPanelAreaWarMainBlockList3D:DoMoveFollow(position)
    local dis = CsDistance(position, self.CameraFollowPoint.transform.position)
    -- y = kx + b, 距离小于 0.5时， 不移动
    local duration =  0.0125 * dis - 0.00625
    if duration <= 0 then
        return
    end
    self.CameraFollowPoint:DOMove(position, duration):SetEase(CsInOutQuart)
end

return XUiPanelAreaWarMainBlockList3D