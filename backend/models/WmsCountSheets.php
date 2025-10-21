<?php

namespace app\models;

use Yii;

/**
 * This is the model class for table "wms_count_sheets".
 *
 * @property int $id
 * @property string $operation_unique_id UUID v4 - multi-device sync
 * @property string $sheet_number COUNT-20251008-15-A3B2
 * @property int $employee_id Sayımı yapan çalışan
 * @property string $warehouse_code Hangi depoda sayım
 * @property string $status
 * @property string|null $notes Kullanıcı yorumu
 * @property string $start_date
 * @property string|null $complete_date
 * @property string $created_at
 * @property string|null $updated_at
 * @property string|null $doc_no
 * @property int $active
 *
 * @property Employees $employee
 */
class WmsCountSheets extends \yii\db\ActiveRecord
{

    /**
     * ENUM field values
     */
    const STATUS_IN_PROGRESS = 'in_progress';
    const STATUS_COMPLETED = 'completed';

    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'wms_count_sheets';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['notes', 'complete_date', 'updated_at', 'doc_no'], 'default', 'value' => null],
            [['status'], 'default', 'value' => 'in_progress'],
            [['active'], 'default', 'value' => 1],
            [['operation_unique_id', 'sheet_number', 'employee_id', 'warehouse_code', 'start_date'], 'required'],
            [['employee_id'], 'integer'],
            [['active'], 'boolean'],
            [['status', 'notes'], 'string'],
            [['start_date', 'complete_date', 'created_at', 'updated_at'], 'safe'],
            [['operation_unique_id', 'sheet_number'], 'string', 'max' => 100],
            [['warehouse_code', 'doc_no'], 'string', 'max' => 45],
            ['status', 'in', 'range' => array_keys(self::optsStatus())],
            [['operation_unique_id'], 'unique'],
            [['sheet_number'], 'unique'],
            [['employee_id'], 'exist', 'skipOnError' => true, 'targetClass' => Employees::class, 'targetAttribute' => ['employee_id' => 'id']],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'id' => 'ID',
            'operation_unique_id' => 'Operation Unique ID',
            'sheet_number' => 'Sheet Number',
            'employee_id' => 'Employee ID',
            'warehouse_code' => 'Warehouse Code',
            'status' => 'Status',
            'notes' => 'Notes',
            'start_date' => 'Start Date',
            'complete_date' => 'Complete Date',
            'created_at' => 'Created At',
            'updated_at' => 'Updated At',
            'doc_no' => 'Doc No',
            'active' => 'Active',
        ];
    }

    /**
     * Gets query for [[Employee]].
     *
     * @return \yii\db\ActiveQuery
     */
    public function getEmployee()
    {
        return $this->hasOne(Employees::class, ['id' => 'employee_id']);
    }


    /**
     * column status ENUM value labels
     * @return string[]
     */
    public static function optsStatus()
    {
        return [
            self::STATUS_IN_PROGRESS => 'in_progress',
            self::STATUS_COMPLETED => 'completed',
        ];
    }

    /**
     * @return string
     */
    public function displayStatus()
    {
        return self::optsStatus()[$this->status];
    }

    /**
     * @return bool
     */
    public function isStatusInprogress()
    {
        return $this->status === self::STATUS_IN_PROGRESS;
    }

    public function setStatusToInprogress()
    {
        $this->status = self::STATUS_IN_PROGRESS;
    }

    /**
     * @return bool
     */
    public function isStatusCompleted()
    {
        return $this->status === self::STATUS_COMPLETED;
    }

    public function setStatusToCompleted()
    {
        $this->status = self::STATUS_COMPLETED;
    }

    /**
     * @return bool
     */
    public function isActive()
    {
        return $this->active == 1;
    }

    public function setActive()
    {
        $this->active = 1;
    }

    public function setInactive()
    {
        $this->active = 0;
    }
}
