local XUiGridAreaWarBlock = require("XUi/XUiAreaWar/XUiGridAreaWarBlock")

local pairs = pairs
local tableInsert = table.insert
local stringFormat = string.format
local MathfLerp = CS.UnityEngine.Mathf.Lerp

local BLOCK_GRID_HEIGHT_LOW = CS.XGame.ClientConfig:GetFloat("AreaWarBlock3DGridHeightMin") --场景中区块对应的3D格子最小高度
local BLOCK_GRID_HEIGHT_HIGH = CS.XGame.ClientConfig:GetFloat("AreaWarBlock3DGridHeightMax") --场景中区块对应的3D格子最大高度
local BLOCK_GRID_ANIM_TIME = CS.XGame.ClientConfig:GetFloat("AreaWarBlock3DGridAnimTime") --场景中区块对应的3D格子动画时间（s）

--区块列表3D的UI
local XUiPanelAreaWarMainBlockList3D = XClass(nil, "XUiPanelAreaWarMainBlockList3D")

function XUiPanelAreaWarMainBlockList3D:Ctor(ui, grids3D, cameras, clickBlockCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Grids3D = grids3D
    self.NearCameras = cameras.StageDetail
    self.FarCameras = cameras.Normal
    self.ClickBlockCb = clickBlockCb
    XTool.InitUiObject(self)
    self.BlockGrids = {}
    self.DelayShowLines = {}
    self.PanelLine = self.Transform:FindTransform("PanelLine")

    --还原上次相机跟随点位置
    local pos = XDataCenter.AreaWarManager.GetLastCameraFollowPointPos()
    if pos then
        self.CameraFollowPoint.transform.localPosition = pos
    else
        local blockIds = XAreaWarConfigs.GetAllBlockIds()
        self.CameraFollowPoint.transform.localPosition = self:GetGridParent(blockIds[1]).transform.localPosition
    end
end

function XUiPanelAreaWarMainBlockList3D:OnDispose()
    XDataCenter.AreaWarManager.SaveLastCameraFollowPointPos(self.CameraFollowPoint.transform.localPosition)
end

function XUiPanelAreaWarMainBlockList3D:Refresh()
    local blockIds = XAreaWarConfigs.GetAllBlockIds()
    for _, blockId in pairs(blockIds) do
        --不可见区块不做更新
        --新解锁的3D格子未看见过升起动画的，不做更新，延迟到动画过程更新
        local checkDic = XDataCenter.AreaWarManager.GetNewUnlockBlockIdDic()
        if not XDataCenter.AreaWarManager.IsBlockVisible(blockId) or checkDic[blockId] then
            self:ResetGridHeight(blockId) --初始化3D格子的高度
            goto CONTINUE
        end

        self:UpdateBlock(blockId)

        ::CONTINUE::
    end
end

function XUiPanelAreaWarMainBlockList3D:UpdateBlock(blockId)
    local parent = self:GetGridParent(blockId)
    if not parent then
        return
    end
    parent.gameObject:SetActiveEx(true)

    --区块信息
    local grid = self.BlockGrids[blockId]
    if not grid then
        local prefabPath = XAreaWarConfigs.GetBlockShowTypePrefab(blockId)
        local go = parent:LoadPrefab(prefabPath)
        local clickCb = handler(self, self.OnClickBlock)
        grid = XUiGridAreaWarBlock.New(go, clickCb)
        self.BlockGrids[blockId] = grid
    end
    grid:Refresh(blockId)
    grid.GameObject:SetActiveEx(true)

    --当前区块可显示，寻找前置区块中已净化的，尝试连线
    local checkDic = XDataCenter.AreaWarManager.GetNewUnlockBlockIdDic()
    local alternativeList = XAreaWarConfigs.GetBlockPreBlockIdsAlternativeList(blockId)
    for _, preBlockIds in pairs(alternativeList) do
        local preBlockId = preBlockIds[1] --只显示并列表中第一个区块的线
        if XDataCenter.AreaWarManager.IsBlockClear(preBlockId) then
            if checkDic[preBlockId] then
                --新解锁区块3D格子的连线延迟到解锁动画播放完毕之后更新
                tableInsert(
                    self.DelayShowLines,
                    {
                        PreBlockId = preBlockId,
                        BlockId = blockId
                    }
                )
            else
                self:TryShowLine(preBlockId, blockId)
            end
        end
    end

    --场景中区块对应的3D格子状态
    local grid3D = self:GetGrid3DTransform(blockId)
    if grid3D then
        grid3D.localPosition =
            Vector3(grid3D.transform.localPosition.x, BLOCK_GRID_HEIGHT_HIGH, grid3D.transform.localPosition.z)
    end
end

--Fucking Line!
function XUiPanelAreaWarMainBlockList3D:TryShowLine(startBlockId, endBlockId)
    local lineName = stringFormat("Line%d_%d", startBlockId, endBlockId)
    local line = self[lineName]
    if not line then
        XLog.Error(
            stringFormat(
                "XUiPanelAreaWarMainBlockList3D:TryShowLine error: UiAreaWarMain3D上找不到对应的区块连线, 前置区块Id: %d, 当前区块Id: %d",
                startBlockId,
                endBlockId
            )
        )
        return
    end
    line.gameObject:SetActiveEx(true)
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

    self.ClickBlockCb(blockId)
end

function XUiPanelAreaWarMainBlockList3D:SetAsBlockChild(transform, blockId)
    local grid = self.BlockGrids[blockId]
    if not grid then
        XLog.Error("XUiPanelAreaWarMainBlockList3D:SetAsBlockChild error: grid not exist, blockId: ", blockId)
        return
    end
    transform:SetParent(grid.Transform.parent, false)
end

--把关卡详情相机跟随目标设至到指定区块
function XUiPanelAreaWarMainBlockList3D:SetDetailCameraFollowBlock(blockId)
    local grid = self.BlockGrids[blockId]
    if not grid then
        XLog.Error(
            "XUiPanelAreaWarMainBlockList3D:SetDetailCameraFollowBlock error: grid not exist, blockId: ",
            blockId
        )
        return
    end
    for _, camera in pairs(self.NearCameras) do
        camera.Follow = grid.Transform
    end

    --隐藏其他区块
    for inBlockId, grid in pairs(self.BlockGrids) do
        grid.Transform.parent.gameObject:SetActiveEx(blockId == inBlockId)
    end
    self.PanelLine.gameObject:SetActiveEx(false)

    --播放格子的近景动画
    grid:PlayNearAnim()
end

--播放格子的远景动画
function XUiPanelAreaWarMainBlockList3D:PlayGridFarAnim(blockId)
    local grid = self.BlockGrids[blockId]
    if not grid then
        XLog.Error("XUiPanelAreaWarMainBlockList3D:PlayGridFarAnim error: grid not exist, blockId: ", blockId)
        return
    end
    grid:PlayFarAnim()
end

--把远景相机跟随目标设至到指定区块（用于控制相机拖拽）
function XUiPanelAreaWarMainBlockList3D:SetNormalCameraFollowBlock(blockId)
    local grid = self.BlockGrids[blockId]
    if not grid then
        XLog.Error(
            "XUiPanelAreaWarMainBlockList3D:SetNormalCameraFollowBlock error: grid not exist, blockId: ",
            blockId
        )
        return
    end
    self.CameraFollowPoint.transform.localPosition = grid.Transform.parent.localPosition

    for _, camera in pairs(self.FarCameras) do
        camera.Follow = self.CameraFollowPoint.transform
    end

    --还原所有区块显示状态
    for _, grid in pairs(self.BlockGrids) do
        grid.Transform.parent.gameObject:SetActiveEx(true)
    end
    self.PanelLine.gameObject:SetActiveEx(true)
end

--初始化3D格子的高度
function XUiPanelAreaWarMainBlockList3D:ResetGridHeight(blockId)
    local grid3D = self:GetGrid3DTransform(blockId)
    if grid3D then
        grid3D.localPosition =
            Vector3(grid3D.transform.localPosition.x, BLOCK_GRID_HEIGHT_LOW, grid3D.transform.localPosition.z)
    end
end

--3D格子升起动画
function XUiPanelAreaWarMainBlockList3D:LetsLift(finishCb)
    --场景中所有可见格子
    local blockIds = XDataCenter.AreaWarManager.GetVisibleBlockIds()
    if XTool.IsTableEmpty(blockIds) then
        finishCb()
        return
    end

    local startY
    local targetY = BLOCK_GRID_HEIGHT_HIGH
    for _, blockId in pairs(blockIds) do
        local pos = self:GetGrid3DTransform(blockId).localPosition
        if pos.y ~= targetY then
            startY = pos.y
            break
        end
    end

    --所有可见格子均已达到最高高度，无需播放动画
    if not startY then
        finishCb()
        return
    end

    local onRefreshFunc = function(time)
        local allAtPos = true
        local newY = MathfLerp(startY, targetY, time)
        for _, blockId in pairs(blockIds) do
            local tf = self:GetGrid3DTransform(blockId)
            if XTool.UObjIsNil(tf) then
                self:StopLiftAnim()
                return true
            end

            local pos = tf.localPosition
            if pos.y ~= targetY then
                allAtPos = false
                tf.localPosition = Vector3(pos.x, newY, pos.z)
            end
        end
        if allAtPos then
            return true
        end
    end

    self:StopLiftAnim()
    self.Timer = XUiHelper.Tween(BLOCK_GRID_ANIM_TIME, onRefreshFunc, finishCb)
end

function XUiPanelAreaWarMainBlockList3D:StopLiftAnim()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiPanelAreaWarMainBlockList3D:GetGrid3DTransform(blockId)
    return self.Grids3D["Panel" .. blockId]
end

function XUiPanelAreaWarMainBlockList3D:GetGridParent(blockId)
    local parent = self["Stage" .. blockId]
    if not parent then
        XLog.Error(
            "XUiPanelAreaWarMainBlockList3D:UpdateInformation error: 地图信息错误，UiAreaWarInformation上找不到对应的Stage节点，blockId：",
            blockId
        )
    end
    return parent
end

function XUiPanelAreaWarMainBlockList3D:RefreshNewUnlockBlocks()
    local checkDic = XDataCenter.AreaWarManager.GetNewUnlockBlockIdDic()
    for blockId in pairs(checkDic) do
        self:UpdateBlock(blockId)
    end

    for _, idPairs in pairs(self.DelayShowLines) do
        self:TryShowLine(idPairs.PreBlockId, idPairs.BlockId)
    end

    XDataCenter.AreaWarManager.SetNewUnlockBlockIdDicCookie(checkDic)
end

return XUiPanelAreaWarMainBlockList3D
