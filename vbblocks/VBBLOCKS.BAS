OPTION EXPLICIT
DEFINT A-Z

DECLARE FUNCTION GetRotatedShapeMap (Shape AS INTEGER, Angle AS INTEGER) AS STRING
DECLARE FUNCTION GetShapeMap (Shape AS INTEGER) AS STRING
DECLARE FUNCTION RandomShapeX () AS INTEGER
DECLARE FUNCTION ShapeCanMove (Map AS STRING, XDirection AS INTEGER, YDirection AS INTEGER) AS INTEGER
DECLARE SUB CheckForFullRows ()
DECLARE SUB CreateShape ()
DECLARE SUB DisplayStatus ()
DECLARE SUB DrawBlock (BlockColor AS STRING, PitX AS INTEGER, PitY AS INTEGER)
DECLARE SUB DrawPit ()
DECLARE SUB DrawShape (EraseShape AS INTEGER)
DECLARE SUB DropShape ()
DECLARE SUB InitializeGame ()
DECLARE SUB Main ()
DECLARE SUB RemoveFullRow (RemovedRow AS INTEGER)
DECLARE SUB SettleActiveShapeInPit ()

CONST BLOCK_SIZE = 24
CONST FALSE = 0
CONST LAST_SIDE_BLOCK = 3
CONST NO_BLOCK$ = "0"
CONST PIT_HEIGHT = 16
CONST PIT_LEFT = 8
CONST PIT_TOP = 2
CONST PIT_WIDTH = 10
CONST SIDE_BLOCK_COUNT = 4
CONST TRUE = -1

DIM SHARED DropRate AS SINGLE
DIM SHARED GameOver AS INTEGER
DIM SHARED Pit AS STRING
DIM SHARED Score AS INTEGER
DIM SHARED Shape AS INTEGER
DIM SHARED ShapeAngle AS INTEGER
DIM SHARED ShapeMap AS STRING
DIM SHARED ShapeX AS INTEGER
DIM SHARED ShapeY AS INTEGER

InitializeGame
Main

SUB CheckForFullRows ()
DIM FullRow AS INTEGER
DIM PitX AS INTEGER
DIM PitY AS INTEGER

    FullRow = FALSE

    FOR PitY = 0 TO PIT_HEIGHT - 1
       FullRow = TRUE
       FOR PitX = 0 TO PIT_WIDTH - 1
           IF MID$(Pit, ((PIT_WIDTH * PitY) + PitX) + 1, 1) = NO_BLOCK$ THEN
              FullRow = FALSE
              EXIT FOR
           END IF
       NEXT PitX
       IF FullRow THEN RemoveFullRow PitY
    NEXT PitY
END SUB

SUB CreateShape ()
    DropRate = 1
    Shape = CINT(RND * 6)
    ShapeAngle = INT(RND * 4)
    ShapeMap = GetRotatedShapeMap(Shape, ShapeAngle)
    ShapeX = RandomShapeX
    ShapeY = -SIDE_BLOCK_COUNT
END SUB

SUB DisplayStatus ()
    COLOR 4
    LOCATE INT((PIT_TOP * BLOCK_SIZE) / 16), INT((PIT_LEFT * BLOCK_SIZE) / 8) + 1
    IF GameOver THEN
        PRINT "Game over - press Enter to play a new game."
    ELSE
        PRINT "Score:" + STR$(Score)
    END IF
END SUB

SUB DrawBlock (BlockColor AS STRING, PitX AS INTEGER, PitY AS INTEGER)
DIM DrawX AS INTEGER
DIM DrawY AS INTEGER

    DrawX = PitX * BLOCK_SIZE
    DrawY = PitY * BLOCK_SIZE

    LINE (DrawX + (PIT_LEFT * BLOCK_SIZE), DrawY + (PIT_TOP * BLOCK_SIZE))-STEP(BLOCK_SIZE, BLOCK_SIZE), VAL("&H" + BlockColor), BF
    LINE (DrawX + CINT(BLOCK_SIZE / 10) + (PIT_LEFT * BLOCK_SIZE), DrawY + CINT(BLOCK_SIZE / 10) + (PIT_TOP * BLOCK_SIZE))-STEP(BLOCK_SIZE - CINT(BLOCK_SIZE / 5), BLOCK_SIZE - CINT(BLOCK_SIZE / 5)), 0, B
END SUB

SUB DrawPit ()
DIM BlockColor AS STRING
DIM PitX AS INTEGER
DIM PitY AS INTEGER

    LINE ((PIT_LEFT * BLOCK_SIZE) - 1, (PIT_TOP * BLOCK_SIZE) - 1)-STEP((PIT_WIDTH * BLOCK_SIZE) + 2, (PIT_HEIGHT * BLOCK_SIZE) + 2), 15, B
    LINE ((PIT_LEFT * BLOCK_SIZE) - 1, (PIT_TOP * BLOCK_SIZE) - 1)-STEP(PIT_WIDTH * BLOCK_SIZE + 2, 0), 0

    FOR PitY = 0 TO PIT_HEIGHT - 1
        FOR PitX = 0 TO PIT_WIDTH - 1
            IF GameOver THEN
                BlockColor = "4"
            ELSE
                BlockColor = MID$(Pit, ((PIT_WIDTH * PitY) + PitX) + 1, 1)
            END IF

            DrawBlock BlockColor, PitX, PitY
        NEXT PitX
    NEXT PitY
END SUB

SUB DrawShape (EraseShape AS INTEGER)
DIM BlockColor AS STRING
DIM BlockX AS INTEGER
DIM BlockY AS INTEGER
DIM PitX AS INTEGER
DIM PitY AS INTEGER

    FOR BlockX = 0 TO LAST_SIDE_BLOCK
        FOR BlockY = 0 TO LAST_SIDE_BLOCK
            PitX = ShapeX + BlockX
            PitY = ShapeY + BlockY
            IF PitX >= 0 AND PitX < PIT_WIDTH AND PitY >= 0 AND PitY < PIT_HEIGHT THEN
                IF EraseShape THEN
                    BlockColor = MID$(Pit, ((PIT_WIDTH * PitY) + PitX) + 1, 1)
                ELSE
                    BlockColor = MID$(ShapeMap, ((SIDE_BLOCK_COUNT * BlockY) + BlockX) + 1, 1)
                    IF BlockColor = NO_BLOCK$ THEN BlockColor = MID$(Pit, ((PIT_WIDTH * PitY) + PitX) + 1, 1)
                END IF
                DrawBlock BlockColor, PitX, PitY
            END IF
        NEXT BlockY
    NEXT BlockX
END SUB

SUB DropShape ()
    IF ShapeCanMove(ShapeMap, 0, 1) THEN
        DrawShape TRUE
        IF DropRate > 0 THEN SOUND 37, .3
        ShapeY = ShapeY + 1
        DrawShape FALSE
    ELSE
        SettleActiveShapeInPit
        
        GameOver = (ShapeY < 0)

        CheckForFullRows
        DrawPit
        DisplayStatus
        
        IF NOT GameOver THEN
            CreateShape
            DrawShape FALSE
        END IF
    END IF
END SUB

FUNCTION GetRotatedShapeMap (Shape AS INTEGER, Angle AS INTEGER) AS STRING
DIM BlockX AS INTEGER
DIM BlockY AS INTEGER
DIM Map AS STRING
DIM NewBlockX AS INTEGER
DIM NewBlockY AS INTEGER
DIM RotatedMap AS STRING

    Map = GetShapeMap(Shape)
    
    IF Angle = 0 THEN
        RotatedMap = Map
    ELSE
        RotatedMap = STRING$(SIDE_BLOCK_COUNT * SIDE_BLOCK_COUNT, NO_BLOCK$)
        FOR BlockX = 0 TO LAST_SIDE_BLOCK
            FOR BlockY = 0 TO LAST_SIDE_BLOCK
                SELECT CASE Angle
                    CASE 1
                        NewBlockX = LAST_SIDE_BLOCK - BlockY
                        NewBlockY = BlockX
                    CASE 2
                        NewBlockX = LAST_SIDE_BLOCK - BlockX
                        NewBlockY = LAST_SIDE_BLOCK - BlockY
                    CASE 3
                        NewBlockX = BlockY
                        NewBlockY = LAST_SIDE_BLOCK - BlockX
                END SELECT

                MID$(RotatedMap, ((SIDE_BLOCK_COUNT * NewBlockY) + NewBlockX) + 1, 1) = MID$(Map, ((SIDE_BLOCK_COUNT * BlockY) + BlockX) + 1, 1)
            NEXT BlockY
        NEXT BlockX
    END IF

    GetRotatedShapeMap = RotatedMap
END FUNCTION

FUNCTION GetShapeMap (Shape AS INTEGER) AS STRING
DIM Map AS STRING

    SELECT CASE Shape
        CASE 0
           Map = "0000333300000000"
        CASE 1
           Map = "0000111000100000"
        CASE 2
           Map = "0000666060000000"
        CASE 3
           Map = "00000EE00EE00000"
        CASE 4
           Map = "0000022022000000"
        CASE 5
           Map = "0000555005000000"
        CASE 6
           Map = "0000440004400000"
        CASE ELSE
           Map = ""
    END SELECT

    GetShapeMap = Map
END FUNCTION

SUB InitializeGame ()
    RANDOMIZE TIMER
    PLAY "ML L64"

    SCREEN 12
    CLS
    COLOR 9
    LOCATE 1, 1
    PRINT "VBBlocks v1.01 - by: Peter Swinkels, ***2025***"

    CreateShape

    GameOver = FALSE
    Pit = STRING$(PIT_WIDTH * PIT_HEIGHT, NO_BLOCK$)
    Score = 0

    DrawPit
    DisplayStatus
END SUB

SUB Main ()
DIM KeyStroke AS STRING
DIM NewAngle AS INTEGER
DIM RotatedMap AS STRING
DIM StartTime AS SINGLE

    StartTime = TIMER
    DO
        DO
            IF NOT GameOver THEN
                IF TIMER >= StartTime + DropRate OR StartTime > TIMER THEN
                    DropShape
                    StartTime = TIMER
                END IF
            END IF
            KeyStroke = INKEY$
        LOOP WHILE KeyStroke = ""
        IF KeyStroke = CHR$(27) THEN
            SCREEN 0
            END
        ELSEIF GameOver THEN
            IF KeyStroke = CHR$(13) THEN InitializeGame
        ELSE
            SELECT CASE KeyStroke
               CASE "A", "a"
                   DrawShape TRUE
                   IF ShapeAngle = 3 THEN NewAngle = 0 ELSE NewAngle = ShapeAngle + 1
                   RotatedMap = GetRotatedShapeMap(Shape, NewAngle)
                   IF ShapeCanMove(RotatedMap, 0, 0) THEN
                       ShapeAngle = NewAngle
                       ShapeMap = RotatedMap
                   END IF
                   DrawShape FALSE
               CASE CHR$(0) + "K"
                   DrawShape TRUE
                   IF ShapeCanMove(ShapeMap, -1, 0) THEN ShapeX = ShapeX - 1
                   DrawShape FALSE
               CASE CHR$(0) + "M"
                   DrawShape TRUE
                   IF ShapeCanMove(ShapeMap, 1, 0) THEN ShapeX = ShapeX + 1
                   DrawShape FALSE
               CASE " "
                   DropRate = 0
            END SELECT
        END IF
    LOOP
END SUB

FUNCTION RandomShapeX () AS INTEGER
DIM IntendedShapeX AS INTEGER
DIM XMove AS INTEGER

    IntendedShapeX = INT(RND * (PIT_WIDTH - 1))
    ShapeX = 0

    FOR XMove = 0 TO IntendedShapeX
        IF ShapeCanMove(ShapeMap, 1, 0) THEN
            ShapeX = ShapeX + 1
        ELSE
            EXIT FOR
        END IF
    NEXT XMove

    RandomShapeX = ShapeX
END FUNCTION

SUB RemoveFullRow (RemovedRow AS INTEGER)
DIM BlockColor AS STRING
DIM PitX AS INTEGER
DIM PitY AS INTEGER

    FOR PitY = RemovedRow TO 0 STEP -1
        FOR PitX = 0 TO PIT_WIDTH - 1
            IF PitY = 0 THEN
                BlockColor = NO_BLOCK$
            ELSE
                BlockColor = MID$(Pit, ((PIT_WIDTH * (PitY - 1)) + PitX) + 1, 1)
            END IF

            MID$(Pit, ((PIT_WIDTH * PitY) + PitX) + 1, 1) = BlockColor
        NEXT PitX
    NEXT PitY

    Score = Score + 1
END SUB

SUB SettleActiveShapeInPit ()
DIM BlockX AS INTEGER
DIM BlockY AS INTEGER
DIM PitX AS INTEGER
DIM PitY AS INTEGER

    PLAY "N21"

    FOR BlockY = 0 TO LAST_SIDE_BLOCK
        FOR BlockX = 0 TO LAST_SIDE_BLOCK
            PitX = ShapeX + BlockX
            PitY = ShapeY + BlockY
            IF PitX >= 0 AND PitX < PIT_WIDTH AND PitY >= 0 AND PitY < PIT_HEIGHT THEN
                IF NOT MID$(ShapeMap, ((SIDE_BLOCK_COUNT * BlockY) + BlockX) + 1, 1) = NO_BLOCK$ THEN
                   MID$(Pit, ((PIT_WIDTH * PitY) + PitX) + 1, 1) = MID$(ShapeMap, ((SIDE_BLOCK_COUNT * BlockY) + BlockX) + 1, 1)
                END IF
            END IF
        NEXT BlockX
    NEXT BlockY
END SUB

FUNCTION ShapeCanMove (Map AS STRING, XDirection AS INTEGER, YDirection AS INTEGER) AS INTEGER
DIM BlockX AS INTEGER
DIM BlockY AS INTEGER
DIM CanMove AS INTEGER
DIM PitX AS INTEGER
DIM PitY AS INTEGER

    CanMove = TRUE

    FOR BlockY = 0 TO LAST_SIDE_BLOCK
        FOR BlockX = 0 TO LAST_SIDE_BLOCK
            IF NOT MID$(Map, ((SIDE_BLOCK_COUNT * BlockY) + BlockX) + 1, 1) = NO_BLOCK$ THEN
                PitX = (ShapeX + BlockX) + XDirection
                PitY = (ShapeY + BlockY) + YDirection
                IF PitX >= 0 AND PitX < PIT_WIDTH AND PitY >= 0 AND PitY < PIT_HEIGHT THEN
                    IF NOT MID$(Pit, (((PIT_WIDTH * PitY) + PitX) + 1), 1) = NO_BLOCK$ THEN
                        CanMove = FALSE
                        EXIT FOR
                    END IF
                ELSEIF PitX < 0 OR PitX >= PIT_WIDTH OR PitY >= PIT_HEIGHT THEN
                    CanMove = FALSE
                    EXIT FOR
                END IF
            END IF
        NEXT BlockX
        IF NOT CanMove THEN EXIT FOR
    NEXT BlockY

    ShapeCanMove = CanMove
END FUNCTION

