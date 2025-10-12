<?php

namespace app\models;

use Yii;

/**
 * This is the model class for table "cash_registers".
 *
 * @property int $id
 * @property string $name
 * @property string $subekodu
 * @property string $cash_out_type
 * @property int $is_active
 * @property string|null $created_at
 * @property string|null $updated_at
 *
 * @property Branches $branch
 */
class CashRegisters extends \yii\db\ActiveRecord
{
    /**
     * ENUM field values
     */
    const CASH_OUT_TYPE_Instant = 'Instant Payment';
    const CASH_OUT_TYPE_Receipt = 'Receipt Only';

    const STATUS_INACTIVE = 0;
    const STATUS_ACTIVE = 1;

    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'cash_registers';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['cash_out_type'], 'default', 'value' => 'manual'],
            [['is_active'], 'default', 'value' => 1],
            [['name', 'subekodu'], 'required'],
            [['cash_out_type','depokodu','subekodu', 'shortname'], 'string'],
            [['is_active'], 'integer'],
            [['created_at', 'updated_at'], 'safe'],
            [['name'], 'string', 'max' => 100],
            ['cash_out_type', 'in', 'range' => array_keys(self::optsCashOutType())],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'id' => 'ID',
            'name' => 'Name',
            'cash_out_type' => 'Cash Out Type',
            'is_active' => 'Is Active',
            'created_at' => 'Created At',
            'updated_at' => 'Updated At',
            'depokodu' => 'Warehouse Code',
            'subekodu' => 'Branch Code',
            'shortname' => 'Prefix',
        ];
    }

    /**
     * Gets query for [[Branch]].
     *
     * @return \yii\db\ActiveQuery
     */
    public function getBranch()
    {
        return $this->hasOne(Branches::class, ['branch_code' => 'subekodu']);
    }

    public static function getCashRegister($id){
        return CashRegisters::find()->where(['id' => $id])->one();
    }


    /**
     * column cash_out_type ENUM value labels
     * @return string[]
     */
    public static function optsCashOutType()
    {
        return [
            self::CASH_OUT_TYPE_Instant => 'Instant Payment',
            self::CASH_OUT_TYPE_Receipt => 'Receipt Only'
        ];
    }

    /**
     * Get status options for dropdown
     * @return array
     */
    public static function optsStatus()
    {
        return [
            self::STATUS_ACTIVE => 'Active',
            self::STATUS_INACTIVE => 'Inactive',
        ];
    }

    /**
     * column cash_out_type ENUM value labels
     * @return string
     */
    public function displayCashOutType()
    {
        return self::optsCashOutType()[$this->cash_out_type];
    }

    /**
     * Get status label
     * @return string
     */
    public function getStatusLabel()
    {
        return self::optsStatus()[$this->is_active];
    }

    /**
     * @return bool
     */
    public function isCashOutTypeManual()
    {
        return $this->cash_out_type === self::CASH_OUT_TYPE_MANUAL;
    }

    public function setCashOutTypeToManual()
    {
        $this->cash_out_type = self::CASH_OUT_TYPE_MANUAL;
    }

    /**
     * @return bool
     */
    public function isCashOutTypeAutomatic()
    {
        return $this->cash_out_type === self::CASH_OUT_TYPE_AUTOMATIC;
    }

    public function setCashOutTypeToAutomatic()
    {
        $this->cash_out_type = self::CASH_OUT_TYPE_AUTOMATIC;
    }

    public function getEmployees()
    {
        return $this->hasMany(Employees::class, ['id' => 'employee_id'])
            ->viaTable('employee_cash_register', ['cash_register_id' => 'id']);
    }
}
