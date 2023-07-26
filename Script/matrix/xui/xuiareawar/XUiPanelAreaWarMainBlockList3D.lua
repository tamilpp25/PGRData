
local CsVector3 = CS.UnityEngine.Vector3
local CsQuaternion = CS.UnityEngine.Quaternion
local NormalPivot = CS.UnityEngine.Vector2(0.5, 0.5)

---@class XUiPanelAreaWarMainBlockList3D
---@field NearCamera UnityEngine.Camera
---@field Line UnityEngine.RectTransform
---@field PanelLine UnityEngine.RectTransform
---@field PanelStage UnityEngine.RectTransform
---@field GridBlocks table<number,XUiGridAreaWarBlock>
---@field BlockScript table<number, XAreaWarBlockArea>
---@field GameObject UnityEngine.GameObject
local XUiPanelAreaWarMainBlockList3D = XClass(nil, "XUiPanelAreaWarMainBlockList3D")
local XUiGridAreaWarBlock = require("XUi/XUiAreaWar/XUiGridAreaWarBlock")

local PositionRatio = 10000


function XUiPanelAreaWarMainBlockList3D:Ctor(ui, cameraData, blockAreas, clickCb, isNormaCameraCb)
    XTool.InitUiObjectByUi(self, ui)
    self.FirstRefresh = true
    self.LinePivot = self.Line.pivot
    self.GridBlocks = {}
    self.GridLines = {}
    self.LineSize = self.Line.sizeDelta
    self.ClickCb = clickCb
    self.ClickBlockCb = handler(self, self.OnClickBlock)
    self.IsNormaCameraCb = isNormaCameraCb
    --偏移一个格子的高度
    self.Offset = nil
    --用于计算的Vector3 避免重复创建对象
    self.CalVec3 = CsVector3.zero
    --相机引用
    self.NearCamera = cameraData.NearCamera
    self.FarCamera = cameraData.FarCamera
    self.NormalVirtual = cameraData.NormalVirtual
    self.DetailVirtual = cameraData.DetailVirtual

    self.IsSmall = false
    
    self:InitAngle()
    self:InitPanel(blockAreas)
end

function XUiPanelAreaWarMainBlockList3D:StartTimer()
    if self.Timer then
        return
    end
    self.Timer = XScheduleManager.ScheduleForever(function() 
        self:Update()
    end, 200)
end

function XUiPanelAreaWarMainBlockList3D:StopTimer()
    if not self.Timer then
        return
    end
    XScheduleManager.UnSchedule(self.Timer)
    self.Timer = nil
end

function XUiPanelAreaWarMainBlockList3D:OnDispose()
    self:StopTimer()
    XDataCenter.AreaWarManager.SaveLastCameraFollowPointPos(self.CameraFollowPoint.transform.position)
end

function XUiPanelAreaWarMainBlockList3D:Update()
    if XTool.UObjIsNil(self.GameObject) then
        return
    end

    if not self.GameObject.activeInHierarchy then
        return
    end

    --if not self:CheckNeedUpdate() then
    --    return
    --end

    for blockId, grid in pairs(self.GridBlocks) do
        local visible
        if self.IsNormaCameraCb() then
            visible = CS.XUiHelper.IsInView(self.NearCamera, grid.Transform.position, -0.2, 1.2, -0.5, 1.2)
            if visible then
                if self.IsSmall then
                    grid:PlayMiniEnable()
                else
                    grid:PlayMiniDisable()
                end
            end
        else
            visible = blockId == self.FocusDetailBlockId
        end
        grid:SetVisible(visible)
        local blockArea = self.BlockScript[blockId]
        if blockArea then
            CS.XUiHelper.WorldPoint2CanvasPoint(self.FarCamera, self.NearCamera, grid.Transform, blockArea:GetCenterPoint(), self.Offset)
        end
    end

    --隐藏时也同步位置，是为了连线时位置是准确的
    --if XTool.UObjIsNil(grid.GameObject) or not grid.GameObject.activeInHierarchy then
    --    return
    --end
end

function XUiPanelAreaWarMainBlockList3D:Refresh(isRepeatChallenge)
    self.IsRepeatChallenge = isRepeatChallenge
    --local checkMap = XDataCenter.AreaWarManager.GetNewUnlockBlockIdDic()
    for _, chapterId in pairs(XAreaWarConfigs.GetChapterIds()) do
        --章节开放
        --if XDataCenter.AreaWarManager.IsChapterUnlock(chapterId) then
        local blockIds = XAreaWarConfigs.GetBlockIdsByChapterId(chapterId)
        for _ ,blockId in pairs(blockIds) do
            if XDataCenter.AreaWarManager.IsBlockVisible(blockId) then
                self:UpdateBlock(blockId)
            end
        end
        --end
    end
    
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

        self:StartTimer()
    end
end

function XUiPanelAreaWarMainBlockList3D:RefreshNewUnlockBlocks()
    local checkMap = XDataCenter.AreaWarManager.GetNewUnlockBlockIdDic()
    for blockId in pairs(checkMap) do
        self:UpdateBlock(blockId)
    end
    
    XDataCenter.AreaWarManager.SetNewUnlockBlockIdDicCookie(checkMap)
end

function XUiPanelAreaWarMainBlockList3D:UpdateBlock(blockId)

    local grid = self.GridBlocks[blockId]
    if not grid then
        local block = self.BlockScript[blockId]
        if not block then
            XLog.Warning("创建事件区域失败! BlockId = " .. blockId)
            return
        end
        if not self.Offset then
            --只偏移高度，因为原点在模型底部中心
            self.Offset = block:GetGridSize()
            self.Offset.x = 0
            self.Offset.z = 0
        end
        self:SetCalVec3(0, 0, block.RotateY)
        grid = self:CreateBlockPanel(blockId, block, self.CalVec3)
        local preBlockIds = XAreaWarConfigs.GetPreBlockIds(blockId)
        --local isUnlock = XDataCenter.AreaWarManager.IsBlockUnlock(blockId)
        for _, preBlockId in pairs(preBlockIds) do
            --preBlockId 类型是string
            local ids = string.Split(preBlockId, "|")
            for _, id in pairs(ids) do
                local numId = tonumber(id)
                if XDataCenter.AreaWarManager.IsBlockVisible(numId) then
                --if isUnlock and XDataCenter.AreaWarManager.IsBlockUnlock(numId) then
                    self:CreateArrowLine(numId, blockId)
                end
            end
        end
    end
    
    grid:Refresh(blockId, self.IsRepeatChallenge)
end

function XUiPanelAreaWarMainBlockList3D:FocusTargetBlock(blockId)
    local grid = self:_GetGridParent(blockId)
    if not grid then
        XLog.Error(
                "XUiPanelAreaWarMainBlockList3D:FocusTargetBlock error: grid not exist, blockId: ",
                blockId
        )
        return
    end
    self.CameraFollowPoint.transform.position = grid.transform.position

    for _, camera in pairs(self.NormalVirtual) do
        camera.Follow = self.CameraFollowPoint.transform
    end

    for id, tempGrid in pairs(self.GridBlocks) do
        tempGrid:SetVisible(true)
    end
    
    self:RefreshLineState(true)
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

    for _, camera in pairs(self.DetailVirtual) do
        camera.Follow = grid.Transform.parent
    end

    for id, tempGrid in pairs(self.GridBlocks) do
        tempGrid:SetVisible(id == blockId)
    end
    
    self:RefreshLineState(false)
    if self.IsSmall then
        grid:PlayMiniDisable()
    end
    grid:PlayNearAnim()
    self.FocusDetailBlockId = blockId
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

--- 初始化面板
---@param blockAreas XAreaWarBlockArea[]
--------------------------
function XUiPanelAreaWarMainBlockList3D:InitPanel(blockAreas)
    local blockMap = {}
    for i = 0, blockAreas.Length - 1 do
        local block = blockAreas[i]
        blockMap[block.Id] = block
    end
    self.BlockScript = blockMap
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

--- 动态创建关卡节点
---@param blockId number
---@param blockArea XAreaWarBlockArea
---@param rotation UnityEngine.Vector3
---@return XUiGridAreaWarBlock
--------------------------
function XUiPanelAreaWarMainBlockList3D:CreateBlockPanel(blockId, blockArea, rotation)
    local name = string.format("Block_%d", blockId)
    local block = XUiHelper.Instantiate(self.Stage, self.PanelStage)
    block.name = name
    block.gameObject:SetActiveEx(true)
    
    local prefabPath = XAreaWarConfigs.GetBlockShowTypePrefab(blockId)
    local go = block.transform:LoadPrefab(prefabPath)
    local grid = XUiGridAreaWarBlock.New(go, self.ClickBlockCb)
    CS.XUiHelper.WorldPoint2CanvasPoint(self.FarCamera, self.NearCamera, block.transform, blockArea:GetCenterPoint(), self.Offset)
    grid:Rotate(CS.UnityEngine.Quaternion.Euler(rotation))
    self.GridBlocks[blockId] = grid
    
    return grid
end

function XUiPanelAreaWarMainBlockList3D:CheckNeedUpdate()
    local lastCameraX = self.LastCameraX or 0
    local lastCameraY = self.LastCameraY or 0
    local lastCameraZ = self.LastCameraZ or 0

    local curCameraX = math.floor(self.NearCamera.transform.position.x * PositionRatio)
    local curCameraY = math.floor(self.NearCamera.transform.position.y * PositionRatio)
    local curCameraZ = math.floor(self.NearCamera.transform.position.z * PositionRatio)
    if lastCameraX ~= curCameraX or lastCameraY ~= curCameraY or lastCameraZ ~= curCameraZ then
        self.LastCameraX = curCameraX
        self.LastCameraY = curCameraY
        self.LastCameraZ = curCameraZ
        return true
    end
    
    return false
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
    if self.ClickCb then self.ClickCb(blockId) end
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

return XUiPanelAreaWarMainBlockList3D