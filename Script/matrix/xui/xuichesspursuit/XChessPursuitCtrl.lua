local XChessPursuitCtrl = {}
local XChessPursuitSceneManager = require("XUi/XUiChessPursuit/XScene/XChessPursuitSceneManager")
local CSXChessPursuitDirection = CS.XChessPursuitDirection

local CSXChessPursuitCtrlCom = nil
local ChessPursuitCubes = {}

XChessPursuitCtrl.MAIN_UI_TYPE = {
    STABLE = 1, --安稳期
    FIGHT_DEFAULT = 2, --斗争期-普通模式
    FIGHT_HARD = 3, --斗争期-炼狱模式
    SCENE = 4, --玩法场景
}

--场景UI的玩法阶段
XChessPursuitCtrl.SCENE_UI_TYPE = {
    BUZHEN = 1, --布阵阶段
    MY_ROUND = 2, --我的回合
    BOSS_ROUND = 3, --BOSS回合
}

--场景UI可选择的目标
XChessPursuitCtrl.SCENE_SELECT_TARGET = {
    NONE = 1, --什么都不可选
    TEAM = 2, --角色
    BOSS = 3, --怪物
    CUBE = 4, --方块
    DEFAULT = 5, --可任意选
}

--一场最多有几张卡
XChessPursuitCtrl.CARD_MAX_COUNT = 3

--@region 场景相关

local function OnLoadCompleteCb(gameObject)
    CSXChessPursuitCtrlCom = gameObject.transform:Find("Playmaker"):GetComponent("XChessPursuitCtrl")
    assert(CSXChessPursuitCtrlCom, "节点Playmaker没有找到XChessPursuitCtrl组件")
    
    XChessPursuitCtrl.Init()
end

local function OnLeaveCb()
    CSXChessPursuitCtrlCom = nil
    for i,v in ipairs(ChessPursuitCubes) do
        v:Dispose()
    end
    ChessPursuitCubes = {}
    XDataCenter.ChessPursuitManager.Clear()
end

function XChessPursuitCtrl.Enter(mapId)
    return XChessPursuitSceneManager.EnterScene(mapId, function(gameObject)
        OnLoadCompleteCb(gameObject)
    end, OnLeaveCb)
end

function XChessPursuitCtrl.LeaveScene()
    XChessPursuitSceneManager.LeaveScene()
end

function XChessPursuitCtrl.PlayAnimationForScene(animName, cbFunc)
    if CSXChessPursuitCtrlCom then
        CSXChessPursuitCtrlCom:PlayAnimationForScene(animName, cbFunc)
    end
end

--@endregion

function XChessPursuitCtrl.Init()
    for i=0,CSXChessPursuitCtrlCom.Cubes.Count-1 do
        local cube = CSXChessPursuitCtrlCom.Cubes[i]
        local XChessPursuitCube = require("XUi/XUiChessPursuit/XScene/XChessPursuitCube")
        table.insert(ChessPursuitCubes, XChessPursuitCube.New(cube))
    end
end

function XChessPursuitCtrl.GetCSXChessPursuitCtrlCom()
    return CSXChessPursuitCtrlCom
end

function XChessPursuitCtrl.GetChessPursuitCubes()
    return ChessPursuitCubes
end

function XChessPursuitCtrl.SetSceneActive(isShow)
    return XChessPursuitSceneManager.SetActive(isShow)
end

--视点坐标-> UGUI坐标 (更准确但需要另外进行缩放)
function XChessPursuitCtrl.WorldToUIPosition(modelPosotion)
    local sceneCamera = CSXChessPursuitCtrlCom.SceneCamera
    local viewportPos = sceneCamera:WorldToViewportPoint(modelPosotion)
    local position = CS.XUiManager.Instance.UiCamera:ViewportToWorldPoint(viewportPos)

    return position
end

--视点坐标-> UGUI坐标
function XChessPursuitCtrl.WorldToUILocaPosition(modelPosotion)
    local sceneCamera = CSXChessPursuitCtrlCom.SceneCamera
    local viewportPos = sceneCamera:WorldToViewportPoint(modelPosotion)
    local uiDesignSize = XGlobalVar.UiDesignSize

    return CS.UnityEngine.Vector2((viewportPos.x - 0.5) * uiDesignSize.Width, (viewportPos.y - 0.5) * uiDesignSize.Height)
end

--获取移动方向
function XChessPursuitCtrl.GetMoveDirection(currentPos, nextPos)
    local step = nextPos - currentPos

    -- STEP绝对值 > 1说明是从首走到尾或从尾走到首（前提是每次只走一步）
    if step > 0 then
        if math.abs(step) > 1 then
            return CSXChessPursuitDirection.Back
        else
            return CSXChessPursuitDirection.Forward
        end
    elseif step < 0 then
        if math.abs(step) > 1 then
            return CSXChessPursuitDirection.Forward
        else
            return CSXChessPursuitDirection.Back
        end
    end
end


return XChessPursuitCtrl