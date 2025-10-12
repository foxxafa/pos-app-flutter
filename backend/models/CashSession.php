<?php

namespace app\models;

use Yii;

/**
 * This is the model class for table "cash_session".
 *
 * @property int $id
 * @property int|null $cash_register_id
 * @property int|null $employee_id
 * @property string|null $start_date
 * @property string|null $end_date
 * @property int|null $float
 * @property float|null $total_net_sales
 * @property int|null $status
 */
class CashSession extends \yii\db\ActiveRecord
{


    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'cash_session';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [[ 'employee_id', 'float'], 'required'],
            [['cash_register_id', 'employee_id', 'status'], 'integer'],
            [['start_date', 'end_date'], 'safe'],
            [['total_net_sales', 'float'], 'number', 'min' => 0],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'id' => 'ID',
            'cash_register_id' => 'Cash Register ID',
            'employee_id' => 'Employee ID',
            'start_date' => 'Start Date',
            'end_date' => 'End Date',
            'float' => 'Float',
            'total_net_sales' => 'Total Net Sales',
            'status' => 'Status',
        ];
    }

}
