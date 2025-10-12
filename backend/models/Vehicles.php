<?php

namespace app\models;

use Yii;

/**
 * This is the model class for table "vehicles".
 *
 * @property int $id
 * @property string $license_plate
 * @property int $wheel_count
 * @property float $weight_limit_kg
 * @property int $vehicle_type_id
 * @property string|null $brand
 * @property string|null $model
 * @property string|null $manufacture_year
 * @property string|null $color
 * @property int|null $is_active
 * @property string|null $created
 * @property string|null $updated
 * @property int|null $user_id
 */
class Vehicles extends \yii\db\ActiveRecord
{


    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'vehicles';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['brand', 'model', 'manufacture_year', 'color', 'user_id'], 'default', 'value' => null],
            [['is_active'], 'default', 'value' => 1],
            [['license_plate', 'weight_limit_kg', 'vehicle_type_id'], 'required'],
            [['wheel_count', 'vehicle_type_id', 'is_active', 'user_id'], 'integer'],
            [['weight_limit_kg'], 'number'],
            [['manufacture_year', 'created', 'updated'], 'safe'],
            [['license_plate'], 'string', 'max' => 20],
            [['brand', 'model'], 'string', 'max' => 50],
            [['color'], 'string', 'max' => 30],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'id' => 'ID',
            'license_plate' => 'License Plate',
            'wheel_count' => 'Wheel Count',
            'weight_limit_kg' => 'Weight Limit Kg',
            'vehicle_type_id' => 'Vehicle Type ID',
            'brand' => 'Brand',
            'model' => 'Model',
            'manufacture_year' => 'Manufacture Year',
            'color' => 'Color',
            'is_active' => 'Is Active',
            'created' => 'Created',
            'updated' => 'Updated',
            'user_id' => 'User ID',
        ];
    }

    public function getVehicleType(){
        return $this->hasOne(VehicleType::className(), ['id' => 'vehicle_type_id']);
    }

    public static function getVehiclesList(){
        return Vehicles::find()->where(['is_active' => 1])->all();
    }

    /**
     * Returns options for active status dropdown
     * @return array status options array
     */
    public static function optsStatus()
    {
        return [
            1 => 'Active',
            0 => 'Disabled'
        ];
    }

}
