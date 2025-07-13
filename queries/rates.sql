select
    RateId as rate_id,
    RateName as rate_name,
    ShortRateName as short_rate_name,
    SettlementAction as settlement_action,
    SettlementTrigger as settement_trigger,
    SettlementValue as settlement_value,
    SettlementType as settlement_type
from hotel.rates
